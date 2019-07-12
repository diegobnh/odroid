import numpy as np
from gym import Env
from gym.spaces import Discrete, MultiDiscrete, MultiBinary, Box
import numpy as np
from gym.utils import seeding
import math
from stable_baselines import A2C, ACER, ACKTR, DQN, DDPG, PPO1, PPO2, TRPO
from stable_baselines.ddpg import AdaptiveParamNoiseSpec
from stable_baselines.common.vec_env import DummyVecEnv
from stable_baselines.common import set_global_seeds
import sys

total_observation_space = 18
eps_stop = 2
num_actions=3
index_state= total_observation_space -2
index_exec_time= total_observation_space -1
max_num_big = 4
max_num_little = 4
map_action_state = [3, 7, 23]
map_reward = [-100, -50, -10, -5, 1, 5, 10, 50, 100, 200]

ref_arquivo = open("Output.txt","w", buffering=1)


'''
* All environments should inherit from gym.Env

* At a minimum you must override a handful of methods:
	step
	reset

* At a minimum you must provide the following attributes(Both are instances of gym.spaces classes)
	action_space
	observation_space


	self.action_space = MultiDiscrete([23,10]) //PPO2 - Actions between [0-22, 0-9]
        self.action_space = MultiDiscrete([23,10]) //DQN - AssertionError: Error: the action space for DQN must be of type gym.spaces.Discrete Não suporta MultiDiscrete!!!
'''


class EnviromentExample(Env):
    '''
     Observation:
        Type: Box(11)
        Num	Observation
        0	LITTLE pmu1 
        1	LITTLE pmu2
        2	LITTLE pmu3
        3       LITTLE pmu4
	4	LITTLE pmu5
	5	BIG pmu1
	6	BIG pmu2
	7	BIG pmu3
	8	BIG pmu4
	9	BIG pmu5
	10	BIG pmu6
	11	BIG pmu7
        11      cpu_migrations
        12      context_switches
        13      LITTLE cpu usage
        14      BIG cpu usage
        15      LITTLE cores enable - this is not send by scheduler 
	16	BIG cores enable - this is not send by sheduler
        17      execution time - just control variables
              
	
    Actions:
        Type: Discrete(2)
        Num	Action
        0	Setup 4l cores
        1	Setup 4b cores
        2	Setup 4b4l cores

    Reward:
        Reward is 0 for every step taken, except the termination step when receive total reward. In this case o reward total is the execution time

    Episode Termination:
        When observation_space[4] is equal -1 that means episode has finished. State equal -1 is an agreement code to sinalize the end of execution.
        Episode length is greater than some big value


    '''


    def __init__(self):
        self.action_space = Discrete(num_actions)
        self.observation_space = Box(low=-1, high=100000, shape=(total_observation_space,))
        self.dim = num_actions
        self.acum_reward = 0
        self.immediate_reward = 0
        self.num_steps = 0
        self.total_time_steps=0
        self.episodes = 0
        self.action_list = []
        self.upper_bound = 0
        self.lower_bound = 0 #smaller execution time
        self.diff_upper_lower = 0
        self.interval = 0
        self.seed(137)
        self.set_limits()

    def seed(self, seed=None):
        self.np_random, seed = seeding.np_random(seed)
        return [seed]

    def set_limits(self):
        f1 = open("1l.time","r")
        f2 = open("1b.time","r")
        time_1l = float(f1.readline().rstrip("\n")) 
        time_1b = float(f2.readline().rstrip("\n"))
        f1.close()
        f2.close() 

        self.upper_bound = time_1l
 
        self.lower_bound = self.upper_bound / (((self.upper_bound/time_1b) * max_num_big ) + max_num_little)
        self.diff_upper_lower =  self.upper_bound - self.lower_bound
        self.interval = self.diff_upper_lower/10
        ref_arquivo.write("Time_1b " + str(time_1b) + "\n" +  "Time_1l " + str(time_1l) + "\n"  + "Perc.Melhoria_l/b " + str("{0:.6f}".format(time_1l/time_1b)) + "\n")
        ref_arquivo.write("Menor_Tempo_Possivel:" + str(str("{0:.2f}".format(self.lower_bound))) + "\n" + "Maior_tempo_Possível(1l) " + str(str("{0:.2f}".format(self.upper_bound))) + "\n")
        ref_arquivo.write("\n\n")
        #ref_arquivo.write("\n") 

    def reset(self):
        self.acum_reward = 0
        self.num_steps = 0
        self.action_list = []
        self.state = self.read_from_scheduler() #The return value is the initial state of observation. INICIA LENDO O ESTADO DO AGENTE 
        return self.state

    def step(self, action):
        self.num_steps += 1
        self.total_time_steps +=1

        config_action = map_action_state[action]

        '''
        if self.episodes == 0:
            a = 0 #1l
        elif self.episodes == 1:
            a = 4 #1b
        elif self.episodes == 2:
            a = 3 #4l
        elif self.episodes == 3:
            a = 7 #4b
        elif self.episodes == 4:
            a = 23 #4b4l
        '''

        item = "T"+ str(self.num_steps) + ":" + str(config_action) 
        self.action_list.append(item)


        done = int(self.state[index_exec_time]) != -1  #Sinaliza que a execução da aplicação acabou
        if done:
           self.episodes += 1

           reward = self.get_final_reward()

           #ref_arquivo.write(str(self.action_list))
           ref_arquivo.write("\n" + "Exec_time:" + str(self.state[index_exec_time]) +  \
                                    " Episodio:" + str(self.episodes)               + \
                                    " Reward:"   + str(reward)                      + \
                                    " Steps:"    + str(self.num_steps)              + \
                                    " "          + str(self.action_list)            + \
                                    "\n")
           ref_arquivo.write("\n")

           if self.episodes == eps_stop:
              self.save_model()
              ref_arquivo.write("Total timesteps:" + str(self.total_time_steps) + "\n")
              ref_arquivo.close()


           self.write_to_scheduler(config_action) #Escrevendo a última ação do episódio para o escalonador

        else:
           reward = self.get_immediate_reward()
           output=""
           for value_state in range(total_observation_space):
                aux1 = "str(\"{0:.2f}\".format(self.state["   
                aux2 = "])) + \"  \" + "
                sample = aux1 + str(value_state) + aux2
                output += sample

           output = output[:-6] + "\\n" + "\""
           ref_arquivo.write(output) 
	 	
	
           self.write_to_scheduler(config_action) #DEPOIS ENVIA UMA A
           self.state = self.read_from_scheduler()


        return self.state, reward, done, {}


    def get_immediate_reward(self):

        self.immediate_reward = self.state[0]#Isso seria o IPC
        self.acum_reward += self.immediate_reward

        return 0
        #return self.immediate_reward #or return 0

    def get_final_reward(self):
        for i in range(0,len(map_reward)):
           if self.state[index_exec_time]  >=  self.upper_bound - ((i+1)*self.interval):
             return map_reward[i]
        #value = self.exec_time_1l/self.state[index_exec_time];

        self.immediate_reward = self.state[0]#Isso seria o IPC
        self.acum_reward += self.immediate_reward

        #return float(self.acum_reward)/self.num_steps
        return self.exec_time_1l/self.state[index_exec_time];

        #return self.immediate_reward
        #current_exec_time = self.state[index_exec_time]
        #if current_exec_time <  (0.9*self.best_exec_time) :
        #     self.best_exec_time = current_exec_time
        #     return 1
        #else:
        #     return -1


    def render(self):
        pass

    def read_from_scheduler(self):
        L_pmu1_str, L_pmu2_str, L_pmu3_str, L_pmu4_str, L_pmu5_str, \
	B_pmu1_str, B_pmu2_str, B_pmu3_str, B_pmu4_str, B_pmu5_str,B_pmu6_str, B_pmu7_str, \
	cpu_migration_str, context_switch_str, cpu_usage_little_str, cpu_usage_big_str, state_str, exec_time_str = input().split() #RECEBIMENTO DO ESTADO DA MAIN

        L_pmu1 = float.fromhex(L_pmu1_str)
        L_pmu2 = float.fromhex(L_pmu2_str)
        L_pmu3 = float.fromhex(L_pmu3_str)
        L_pmu4 = float.fromhex(L_pmu4_str)
        L_pmu5 = float.fromhex(L_pmu5_str)
        B_pmu1 = float.fromhex(B_pmu1_str)
        B_pmu2 = float.fromhex(B_pmu2_str)
        B_pmu3 = float.fromhex(B_pmu3_str)
        B_pmu4 = float.fromhex(B_pmu4_str)
        B_pmu5 = float.fromhex(B_pmu5_str)
        B_pmu6 = float.fromhex(B_pmu6_str)
        B_pmu7 = float.fromhex(B_pmu7_str)

        cpu_migration = float.fromhex(cpu_migration_str)
        context_switch = float.fromhex(context_switch_str)

        cpu_usage_little  = float.fromhex(cpu_usage_little_str)
        cpu_usage_big  = float.fromhex(cpu_usage_big_str)

        if int(state_str) == 3:
           num_big = 0
           num_little = 4
        elif int(state_str) == 7:
           num_big = 4
           num_little = 0
        elif int(state_str) == 23:
           num_big = 4
           num_little = 4
        else:
           num_big = -1
           num_little = -1
        exec_time = float(exec_time_str)


        return np.array([L_pmu1, L_pmu2, L_pmu3, L_pmu4, L_pm5, \
			 B_pmu1, B_pmu2, B_pmu3, B_pmu4, B_pmu5,B_pmu6, B_pmu7, \
			 cpu_migration, context_switch, cpu_usage_little, cpu_usage_big, num_little, num_big, exec_time])

    def write_to_scheduler(self, action):
        print (action)


    def save_model(self):
        model.save("dqn_model") 



env = DummyVecEnv([lambda: EnviromentExample()])
#model = PPO2(policy="MlpLstmPolicy", tensorboard_log="./ppo2_tensorborad/",env=env, n_steps=6, nminibatches=1)
model = DQN(policy="MlpPolicy", tensorboard_log="./dqn_tensorborad/", batch_size=16, env=env)
model.learn(total_timesteps=int(2.1e+4))

'''
env = DummyVecEnv([lambda: EnviromentExample()])
model = PPO2.load("ppo2_model.pkl")
obs = env.reset()

while True:
    action, _ = model.predict(obs)

    obs, reward, done, _ = env.step(action)
    if done:
        break


del model, env
'''

