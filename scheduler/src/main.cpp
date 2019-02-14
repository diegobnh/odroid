#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <cassert>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include "perf.hpp"

char** environ;

static int scheduler_input_pipe = -1;
static int scheduler_output_pipe = -1;
static int scheduler_pid = -1;
static int application_pid = -1;

enum State
{
    STATE_L,
    STATE_B,
    STATE_BL,
};

static State current_state = STATE_BL;
static double current_state_mips = 0.0;

static void send_to_scheduler(const char* fmt, ...)
{
    char buffer[512];

    va_list va;
    va_start(va, fmt);
    int count = vsnprintf(buffer, sizeof(buffer) - 1, fmt, va);
    va_end(va);

    if(count < 0)
    {
        perror("scheduler: failed to vsnprintf during send_to_scheduler");
        abort();
    }
    else
    {
        buffer[count++] = '\n';
        buffer[count] = '\0';

        int written = write(scheduler_input_pipe, buffer, count);
        if(written == -1)
        {
            perror("scheduler: failed to write to scheduler");
            abort();
        }
        else if(written != count)
        {
            fprintf(stderr, "scheduler: count mismatch during send_to_scheduler\n");
            abort();
        }
    }
}

static void recv_from_scheduler(const char* fmt, ...)
{
    int count = 0;
    char buffer[512];

    while(count == 0 || buffer[count-1] != '\n')
    {
        const auto result = read(scheduler_output_pipe, buffer, sizeof(buffer) - count);
        if(result <= 0)
        {
            perror("scheduler: failed to read from scheduler pipe\n");
            abort();
        }

        count += result;
        assert(count < (int) sizeof(buffer) - 1);
    }

    va_list va;
    va_start(va, fmt);
    vsscanf(buffer, fmt, va);
    va_end(va);
}

static void cleanup()
{
    fprintf(stderr, "scheduler: cleaning up\n");

    if(application_pid != -1)
    {
        kill(application_pid, SIGTERM);
        waitpid(application_pid, nullptr, 0);
        application_pid = -1;
    }

    if(scheduler_pid != -1)
    {
        kill(scheduler_pid, SIGTERM);
        waitpid(scheduler_pid, nullptr, 0);
        scheduler_pid = -1;
    }

    if(scheduler_input_pipe != -1)
    {
        close(scheduler_input_pipe);
        scheduler_input_pipe = -1;
    }

    if(scheduler_output_pipe != -1)
    {
        close(scheduler_output_pipe);
        scheduler_output_pipe = -1;
    }
}

static bool spawn_scheduling_process(const char* command)
{
    int inpipefd[2] = {-1, -1};
    int outpipefd[2] = {-1, -1};

    if(pipe(inpipefd) == -1 || pipe(outpipefd) == -1)
    {
        perror("scheduler: failed to create scheduling pipes.");
        return false;
    }

    int pid = fork();
    if(pid == -1)
    {
        perror("scheduler: failed to fork scheduler");
        close(inpipefd[0]);
        close(inpipefd[1]);
        close(outpipefd[0]);
        close(outpipefd[1]);
        return false;
    }
    else if(pid == 0)
    {
        dup2(outpipefd[0], STDIN_FILENO);
        dup2(inpipefd[1], STDOUT_FILENO);

        close(outpipefd[1]);
        close(inpipefd[0]);

        // receive SIGTERM once the parent process dies
        prctl(PR_SET_PDEATHSIG, SIGTERM);

        execl("/bin/sh", "sh", "-c", command, NULL);
        perror("scheduler: execl failed");
        return false;
    }
    else
    {
        close(outpipefd[0]);
        close(inpipefd[1]);
        ::scheduler_pid = pid;
        ::scheduler_input_pipe = outpipefd[1];
        ::scheduler_output_pipe = inpipefd[0];
        return true;
    }
}

static bool spawn_scheduled_application(char* argv[])
{
    int pid = fork();
    if(pid == -1)
    {
        perror("scheduler: failed to fork scheduled application");
        return false;
    }
    else if(pid == 0)
    {
        execvp(argv[0], argv);
        perror("scheduler: execvp failed");
        return false;
    }
    else
    {
        ::application_pid = pid;
        return true;
    }
}

static void update_scheduler()
{
    uint64_t total_cycles = 0;
    uint64_t total_instructions = 0;
    uint64_t total_cache_miss = 0;
    uint64_t total_branch_inst = 0;
    uint64_t total_branch_miss = 0;

    for(int cpu = 0, max_cpu = perf_nprocs(); cpu < max_cpu; ++cpu)
    {
        const auto hw_data = perf_consume_hw(cpu);
        total_cycles += hw_data.cpu_cycles;
        total_instructions += hw_data.instructions;
        total_cache_miss += hw_data.cache_misses;
        total_branch_inst += hw_data.branch_instructions;
        total_branch_miss += hw_data.branch_misses;
    }

    double mkpi = ((double)(total_cache_miss) / (double)(total_instructions)) * 1000.0;
    double bmiss = double(total_branch_miss) / double(total_branch_inst);
    double ipc = double(total_instructions) / double(total_cycles);

    State next_state = current_state;
    double next_state_mips = 0.0;

    for(int i = 0; i <= 2; ++i)
    {
        assert(i == STATE_BL || i == STATE_B || i == STATE_L);

        const bool has_big = (i == STATE_BL || i == STATE_B);
        const bool has_little = (i == STATE_BL || i == STATE_L);

        double expected_mips;
        send_to_scheduler("%a %a %a %d %d", mkpi, bmiss, ipc, has_big, has_little);
        recv_from_scheduler("%lf", &expected_mips);

        if(expected_mips > next_state_mips)
        {
            next_state_mips = expected_mips;
            next_state = static_cast<State>(i);
        }
    }

    if(next_state != current_state)
    {
        char buffer[512];
        auto cfg = (next_state == STATE_L? "0-3" :
                    next_state == STATE_B? "4-7" :
                                           "0-7");
        sprintf(buffer, "taskset -pac %s %d >/dev/null", cfg, application_pid);
        fprintf(stderr, "scheduler: %s\n", buffer);

        int status = system(buffer);
        if(status == -1)
        {
            perror("scheduler: system() failed");
        }
        else if(status != 0)
        {
            fprintf(stderr, "scheduler: taskset returned %d :(\n", status);
        }

        current_state = next_state;
        current_state_mips = next_state_mips;
    }
}

int main(int argc, char* argv[])
{
    if(argc < 2)
    {
        fprintf(stderr, "usage: %s command args...\n", argv[0]);
        return 1;
    }

    //const auto command = std::getenv("SCHED_COMMAND");
    const auto command = "python3 ./dumb-scheduler.py";
    if(!command)
    {
        fprintf(stderr, "scheduler: please specify the scheduler command "
                        "through the SCHED_COMMAND environment variable.");
        return 1;
    }

    if(!spawn_scheduling_process(command))
    {
        cleanup();
        return 1;
    }

    if(!spawn_scheduled_application(&argv[1]))
    {
        cleanup();
        return 1;
    }

    perf_init();

    while(::application_pid != -1)
    {
        usleep(20000); // 20ms

        int pid = waitpid(::application_pid, NULL, WNOHANG);
        if(pid == -1)
        {
            perror("scheduler: waitpid in main loop failed");
        }
        else if(pid != 0)
        {
            assert(pid == ::application_pid);
            application_pid = -1;
        }
        else
        {
            update_scheduler();
        }
    }

    fprintf(stderr, "scheduler: main application finished\n");
    perf_shutdown();
    cleanup();

    return 0;
}
