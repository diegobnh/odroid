#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <cassert>
#include <cinttypes>
#include <cstring>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include <linux/limits.h>
#include <signal.h> 
#include "perf.hpp"
#include "time.hpp"
#include "states.hpp" 

#define FLAG_ONLY_PARALLEL_REGION 0
#define NUM_EPISODES 1000

#ifndef SCHEDULER_TYPE
#   error Please define SCHEDULER_TYPE
#endif

#if !(SCHEDULER_TYPE >= 0 && SCHEDULER_TYPE <= 2)
#   error SCHEDULER_TYPE must be 0, 1 or 2
#endif

#define SCHEDULER_TYPE_COLLECT 0
#define SCHEDULER_TYPE_PREDICTOR 1
#define SCHEDULER_TYPE_AGENT 2

char** environ;

static FILE* collect_stream = 0;
static FILE* cpu_utilization_stream = 0;
static int scheduler_input_pipe = -1;
static int scheduler_output_pipe = -1;
static int scheduler_pid = -1;
static int application_pid = -1;
static uint64_t application_start_time = 0;
static State current_state;
static int num_time_steps = 0;
static int flag_update_schedule;


static void update_scheduler_to_serial_region();


void get_cpu_usage(double *cpu_usage)
{
    if(::application_pid == -1)
    {
        cpu_usage[0] = 0.0;
        cpu_usage[1] = 0.0;
        return;
    }

    int count = 0;
    char buffer[256];
    sprintf(buffer, "ps -p %d -mo pcpu,psr", ::application_pid);
    cpu_utilization_stream = popen(buffer, "r");
    if(!cpu_utilization_stream)
    {
        perror("failed to collect cpu usage");
        cpu_usage[0] = 0.0;
        cpu_usage[1] = 0.0;
        return;
    }

    double total_cluster_little = 0.0;
    double total_cluster_big    = 0.0;

    // skip %CPU
    count = 0;
    buffer[0] = 0;
    while(count == 0 || buffer[count-1] != '\n')
    {
        if(!fgets(&buffer[count], sizeof(buffer), cpu_utilization_stream))
            break;
        count = strlen(buffer);
    }

    // skip total
    count = 0;
    buffer[0] = 0;
    while(count == 0 || buffer[count-1] != '\n')
    {
        if(!fgets(&buffer[count], sizeof(buffer), cpu_utilization_stream))
            break;
        count = strlen(buffer);
    }

    // iterate on the next lines
    while(true)
    {
        count = 0;
        buffer[0] = 0;
        while(count == 0 || buffer[count-1] != '\n')
        {
            if(!fgets(&buffer[count], sizeof(buffer), cpu_utilization_stream))
                break;
            count = strlen(buffer);
        }

        if(count == 0)
            break;

        double row_cpu_usage;
        int row_cpu_core;
        sscanf(buffer, "%lf %d", &row_cpu_usage, &row_cpu_core);

        if(row_cpu_core >= 0 && row_cpu_core <= 3)
            total_cluster_little += row_cpu_usage;
        else
            total_cluster_big += row_cpu_usage;
    }

    fclose(cpu_utilization_stream);

    cpu_usage[0] = total_cluster_little;
    cpu_usage[1] = total_cluster_big;
    //fprintf(stderr, "Inside CPU utilization Little:%lf\t Big:%lf  Current_state:%d\n", cpu_usage[0], cpu_usage[1], current_state);
}



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

    if(collect_stream != 0)
    {
        fclose(collect_stream);
        collect_stream = 0;
    }
}

static bool create_logging_file()
{


#ifdef PMCS_A15_ONLY
     char pmcs[10][35] ={  "0x01_0x02_0x03_0x04_0x05_0x08",
                           "0x09_0x10_0x12_0x13_0x14_0x15",
                           "0x16_0x17_0x18_0x19_0x1B_0x1D",
                           "0x40_0x41_0x42_0x43_0x46_0x47",
                           "0x48_0x4C_0x4D_0x50_0x51_0x52",
                           "0x53_0x56_0x58_0x60_0x61_0x62",
                           "0x64_0x66_0x67_0x68_0x69_0x6A",
                           "0x6C_0x6D_0x6E_0x70_0x71_0x72",
                           "0x73_0x74_0x75_0x76_0x78_0x79",
                           "0x7A_0x7E_0x00_0x00_0x00_0x00"};

#elif defined PMCS_A7_ONLY
    char pmcs[9][35] ={ "0x01_0x02_0x03_0x04",
                        "0x05_0x06_0x07_0x08",
                        "0x09_0x0A_0x0C_0x0D",
                        "0x0E_0x0F_0x10_0x12",
                        "0x13_0x14_0x15_0x16",
                        "0x17_0x18_0x19_0x1D",
                        "0x60_0x61_0xC0_0xC1",
                        "0xC4_0xC5_0xC6_0xC9",
                        "0xCA_0x00_0x00_0x00"};
#endif

    static int index_pmc=0;
    char filename[PATH_MAX];

#if defined PMCS_A7_ONLY || defined PMCS_A15_ONLY 
    if(index_pmc >=0 && index_pmc<=10){
       sprintf(filename, "%s.csv", pmcs[index_pmc]);
       index_pmc ++;
    }
#else
    sprintf(filename, "scheduler_%d.csv", application_pid); //getpid() get fathers'pid  
#endif


    collect_stream = fopen(filename, "w");
    if(!collect_stream)
    {
        perror("scheduler: failed to open logging file");
        return false;
    }
    fprintf(stderr, "scheduler: collecting to file %s\n", filename);
    //fprintf(collect_stream, "#ElapsedTime,L_cycles,L_pmu1,L_pmu2,L_pmu3,L_pmu4,B_cycles,B_pmu1,B_pmu2,B_pmu3,B_pmu4,B_pmu5,B_pmu6,CpuMigration,ContextSwitch,LittleUtilization,BigUtilization\n") ;

    return true;
}

static bool create_time_file(uint64_t time_ms)
{
    char filename[PATH_MAX];
    sprintf(filename, "scheduler_%d.time", getpid());
    FILE* time_stream = fopen(filename, "w");
    if(!time_stream)
    {
        perror("scheduler: failed to open time file");
        return false;
    }
    fprintf(time_stream, "%" PRIu64, time_ms);
    fprintf(time_stream, "\n");
    return true;
}

static bool spawn_agent(const char* command)
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

static bool spawn_application(char* argv[])
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
        ::application_start_time = get_time();
        ::current_state = STATE_4b;
        //update_scheduler_to_serial_region();
        return true;
    }
}


static void update_scheduler_to_serial_region()
{
//    if(::application_pid != -1 && current_state != STATE_4b)
    if(::application_pid != -1)
    {
        char buffer[512];
        auto cfg = configs[STATE_4b];

        sprintf(buffer, "taskset -pac %s %d >/dev/null", cfg, application_pid);

        int status = system(buffer);
        if(status == -1)
        {
            perror("scheduler: system() failed");
        }
        else if(status != 0)
        {
            fprintf(stderr, "scheduler: taskset returned %d :(\n", status);
        }

        current_state = STATE_4b;
    }

}

static void update_scheduler()
{
    double cpu_usage[2];
    get_cpu_usage(cpu_usage);


    double l_total_pmu_1 = 0;
    double l_total_pmu_2 = 0;
    double l_total_pmu_3 = 0;
    double l_total_pmu_4 = 0;
    double l_total_pmu_5 = 0;

    double b_total_pmu_1 = 0;
    double b_total_pmu_2 = 0;
    double b_total_pmu_3 = 0;
    double b_total_pmu_4 = 0;
    double b_total_pmu_5 = 0;
    double b_total_pmu_6 = 0;
    double b_total_pmu_7 = 0;


    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {
        const auto hw_data = perf_consume_hw(cpu);
        l_total_pmu_1 += (double)hw_data.pmu_1;   //cycles
        l_total_pmu_2 += (double)hw_data.pmu_2;   //instructions
        l_total_pmu_3 += (double)hw_data.pmu_3;   //cache_misses
        l_total_pmu_4 += (double)hw_data.pmu_4;   //bus access
        l_total_pmu_5 += (double)hw_data.pmu_5;   //l2 cache refill

    }

    for(int cpu = START_INDEX_BIG; cpu < END_INDEX_BIG; ++cpu)
    {
        const auto hw_data = perf_consume_hw(cpu);
        b_total_pmu_1 += (double)hw_data.pmu_1;   //cycles
        b_total_pmu_2 += (double)hw_data.pmu_2;   //instructions
        b_total_pmu_3 += (double)hw_data.pmu_3;   //cache_misses
        b_total_pmu_4 += (double)hw_data.pmu_4;   //bus access
        b_total_pmu_5 += (double)hw_data.pmu_5;   //l2 cache refill
        b_total_pmu_6 += (double)hw_data.pmu_6;   //bus access
        b_total_pmu_7 += (double)hw_data.pmu_7;   //l2 cache refill

    }

    double total_cpu_migration = 0;
    double total_context_switch = 0;


    for(int cpu = 0, max_cpu = perf_nprocs(); cpu < max_cpu; ++cpu)
    {
        const auto sw_data = perf_consume_sw(cpu);
        total_cpu_migration += (double)sw_data.cpu_migrations;
        total_context_switch += (double)sw_data.context_switches;
    }

    const uint64_t elapsed_time = to_millis(get_time() - ::application_start_time);
    State next_state = current_state;

#if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT

#ifdef PMCS_A15_ONLY
    /* fprintf(stderr,"%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                   "%.2lf,%.2lf,%.2lf,%.2lf\n", \
                   b_total_pmu_1, b_total_pmu_2, b_total_pmu_3, b_total_pmu_4, b_total_pmu_5, b_total_pmu_6, b_total_pmu_7, \
                   total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);
    */
    fprintf(collect_stream, "%" PRIu64 \
                            ",%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                            "%.2lf,%.2lf,%.2lf,%.2lf\n" ,
                            elapsed_time, \
                            b_total_pmu_1, b_total_pmu_2, b_total_pmu_3, b_total_pmu_4, b_total_pmu_5, b_total_pmu_6, b_total_pmu_7, \
                            total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);


#elif defined PMCS_A7_ONLY    
    /*fprintf(stderr,"%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                   "%.2lf,%.2lf,%.2lf,%.2lf\n", \
                   l_total_pmu_1, l_total_pmu_2, l_total_pmu_3, l_total_pmu_4, l_total_pmu_5, \
                   total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);
    */

    fprintf(collect_stream, "%" PRIu64 \
                            ",%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                            "%.2lf,%.2lf,%.2lf,%.2lf\n" ,
                            elapsed_time, \
                            l_total_pmu_1, l_total_pmu_2, l_total_pmu_3, l_total_pmu_4, l_total_pmu_5, \
                            total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);


#else
    fprintf(stderr,"%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                   "%.2lf,%.2lf,%.2lf,%.2lf\n", \
                   l_total_pmu_1, l_total_pmu_2, l_total_pmu_3, l_total_pmu_4, l_total_pmu_5, \
                   b_total_pmu_1, b_total_pmu_2, b_total_pmu_3, b_total_pmu_4, b_total_pmu_5, b_total_pmu_6, b_total_pmu_7, \
                   total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);

    fprintf(collect_stream, "%" PRIu64 \
                            ",%lf,%lf,%lf,%lf,%lf," \
                            "%lf,%lf,%lf,%lf,%lf,%lf,%lf," \
                            "%.2lf,%.2lf,%.2lf,%.2lf\n" ,
                            elapsed_time, \
                            l_total_pmu_1, l_total_pmu_2, l_total_pmu_3, l_total_pmu_4, l_total_pmu_5, \
                            b_total_pmu_1, b_total_pmu_2, b_total_pmu_3, b_total_pmu_4, b_total_pmu_5, b_total_pmu_6, b_total_pmu_7, \
                            total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);
#endif



#elif SCHEDULER_TYPE == SCHEDULER_TYPE_PREDICTOR || SCHEDULER_TYPE == SCHEDULER_TYPE_AGENT  
    int state_index_reply;
    float exec_time = -1.0;

    send_to_scheduler("%a %a %a %a %a %a %a %a %a %a %a %a %a %a %a %a %d %f", \
                      l_total_pmu_1, l_total_pmu_2, l_total_pmu_3, l_total_pmu_4, l_total_pmu_5, \
                      b_total_pmu_1, b_total_pmu_2, b_total_pmu_3, b_total_pmu_4, b_total_pmu_5, b_total_pmu_6, b_total_pmu_7, \
                      total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1], \
                      current_state, exec_time);

    recv_from_scheduler("%d", &state_index_reply);//Here is State enumerate
    ::num_time_steps += 1;
    next_state = static_cast<State>(state_index_reply);
#endif


    if(::application_pid != -1 && next_state != current_state)
    {
        char buffer[512];
        auto cfg = configs[next_state];//extern variable declared in States.h

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
    }
    
}


void sig_handler(int signo)
{
    if (signo == SIGUSR1){
       fprintf(stderr, "received SIGUSR1\n");
#if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT
        if(FLAG_ONLY_PARALLEL_REGION == 1){
             update_scheduler();
             ::flag_update_schedule = 0;
        }
#elif SCHEDULER_TYPE == SCHEDULER_TYPE_AGENT
        usleep(600000);
        update_scheduler();
#endif

    }
    else if (signo == SIGUSR2){
       fprintf(stderr, "received SIGUSR2\n"); 
#if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT
       if(FLAG_ONLY_PARALLEL_REGION == 1){
          ::flag_update_schedule = 1;
          fprintf(collect_stream, "\n"); 
       }
       //update_scheduler_to_serial_region();
#endif

    }
}


int main(int argc, char* argv[])
{

    ::flag_update_schedule = FLAG_ONLY_PARALLEL_REGION ;
    signal(SIGUSR1, sig_handler);
    signal(SIGUSR2, sig_handler);

    if(argc < 2)
    {
        fprintf(stderr, "usage: %s command args...\n", argv[0]);
        return 1;
    }

#if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT

#if defined PMCS_A15_ONLY
    const int num_episodes = 10;//number of time to collect all pmcs from big core
#elif defined PMCS_A7_ONLY
    const int num_episodes = 9;//number of time to collect all pmcs from little core
#else
    const int num_episodes = 1;
#endif

#elif SCHEDULER_TYPE == SCHEDULER_TYPE_PREDICTOR
    const int num_episodes = 1; // Predictor should run a single episode
    if(!spawn_agent("python3 ./predictor.py"))
    {
        cleanup();
        return 1;
    }
#elif SCHEDULER_TYPE == SCHEDULER_TYPE_AGENT
    const int num_episodes = NUM_EPISODES;
    char cmd[50];
    sprintf(cmd, "python3 %s", argv[1]);

    if(!spawn_agent(cmd))
    {
        cleanup();
        return 1;
    }
    fprintf(stderr, "Waiting to load the agent..\n\n");
    sleep(25);//time to wait for the agent to load their libraries and be ready to make decisions.
    fprintf(stderr, "Total of episodios: %d\n", num_episodes);
#endif



    for(int curr_episode = 0; curr_episode < num_episodes; ++curr_episode)
    {
        perf_init();

#if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT
        if(!create_logging_file())
        {
            cleanup();
            return 1;
        }
        if(!spawn_application(&argv[1]))
#elif SCHEDULER_TYPE == SCHEDULER_TYPE_AGENT
        if(!spawn_application(&argv[2]))
#endif
        {
            cleanup();
            return 1;
        }

        fprintf(stderr, "\n\nscheduler: starting episode %d with pid %d\n\n", curr_episode + 1, application_pid);

        while(::application_pid != -1)
        {
            int pid = waitpid(::application_pid, NULL, WNOHANG);

            if(pid == -1)
            {
                perror("scheduler: waitpid in main loop failed");
            }
            else if(pid != 0)
            {
                assert(pid == ::application_pid);
                application_pid = -1;

                #if SCHEDULER_TYPE == SCHEDULER_TYPE_AGENT
                float exec_time;
                int state_index_reply;
                if(::application_pid == -1) // end of episode
                {
                     exec_time = to_millis(get_time() - ::application_start_time);
                     send_to_scheduler("%a %a %a %a %a %a %a %a %a %a %a %a %a %a %a %a %d %f", \
                                       0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-1,exec_time);

                     recv_from_scheduler("%d", &state_index_reply);
                     //create_time_file(exec_time);
                }
                #endif
            }
            #if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT
            else if(!(flag_update_schedule == 1))
            {
                update_scheduler();
            }
            #endif
            usleep(200000);//20 miliseconds
        }

        perf_shutdown();


        #if SCHEDULER_TYPE == SCHEDULER_TYPE_PREDICTOR || SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT
              create_time_file(to_millis(get_time() - ::application_start_time));
        #endif

        usleep(5000000); //only to clear anything in cpu - 2 seconds
        fprintf(stderr, "scheduler: episode %d finished\n", curr_episode + 1);
    }

    cleanup();
    return 0;
}
