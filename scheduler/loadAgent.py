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

num_actions=3
index_state=6
index_exec_time=7

map_action_state = [3, 7, 23]

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
        Type: Box(6)
        Num	Observation
        0	pmu1
        1	pmu2
        2	pmu3
        3       pmu4
        4       cpu usage little
        5       cpu usage big
        6       state
        7       exec_time


    Actions:
        Type: Discrete(2)
        Num	Action
        0	Setup 4l cores
        1	Setup 4b cores
        2	Setup 4b4l cores

    Reward:
        Reward is 0 for every step taken, except the termination step when receive total reward. In this case o reward total is the execution time

    Episode Termination:
        When observation_space[4] is equal -1. State equal -1 is an agreement code to sinalize the end of execution.
        Episode length is greater than some big value


    '''


    def __init__(self):
        self.action_space = Discrete(num_actions)
        self.observation_space = Box(low=-1, high=100000, shape=(8,))
        self.dim = num_actions
        self.acum_reward = 0
        self.immediate_reward = 0
        self.num_steps = 0
        self.exec_time_1l = 52740
        self.total_time_steps=0
        self.episodes = 0
        self.action_list = []


    def seed(self, seed=None):
        self.np_random, seed = seeding.np_random(1237)
        return [seed]

    def reset(self):
        self.acum_reward = 0
        self.num_steps = 0
        self.action_list = []
        self.state = self.read_from_scheduler() #The return value is the initial state of observation. INICIA LENDO O ESTADO DO AGENTE 
        return self.state

    def step(self, action):
        self.num_steps += 1
        self.total_time_steps +=1


        a = map_action_state[action]


        item = "A"+ str(self.num_steps) + ":" + str(a) 
        self.action_list.append(item)


        done = int(self.state[index_state]) == -1  #Sinaliza que a execução da aplicação acabou
        if done:
           self.episodes += 1

           reward = self.get_final_reward()

           #ref_arquivo.write(str(self.action_list))
           ref_arquivo.write("\n" + "Exec_time:" + str(self.state[index_exec_time]) + " Episodio:" + str(self.episodes) +  " Reward:" +  str(reward) + " Steps:" + str(self.num_steps) + " " + str(self.action_list) +  "\n")
           ref_arquivo.write("\n")

           if self.episodes == 1500:
              self.save_model()
              ref_arquivo.write("Total timesteps:" + str(self.total_time_steps) + "\n")
              ref_arquivo.close()


           self.write_to_scheduler(a) #Escrevendo a última ação do episódio para o escalonador


        else:
           reward = self.get_immediate_reward()
           ref_arquivo.write(str("{0:.6f}".format(self.state[0])) + "  " + str("{0:.6f}".format(self.state[1])) + "  " + str("{0:.6f}".format(self.state[2])) + "  " + str("{0:.6f}".format(self.state[3])) + "  " + str("{0:.6f}".format(self.state[4])) + "  " + str("{0:.6f}".format(self.state[5]) + "  Acao:" + str(a) + "\n") )

           self.write_to_scheduler(a) #DEPOIS ENVIA UMA A
           self.state = self.read_from_scheduler()


        return self.state, reward, done, {}



    def get_immediate_reward(self):

        self.immediate_reward = self.state[0]#Isso seria o IPC
        self.acum_reward += self.immediate_reward

        return 0
        #return self.immediate_reward #or return 0

    def get_final_reward(self):

        value = self.exec_time_1l/self.state[index_exec_time];
        #if value < 2.0:
           #return -1
        if value < 5.00:
          return -1
        elif value < 7.00:
          return 10
        else:
          return 50


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
        pmu1_str, pmu2_str, pmu3_str, pmu4_str, cpu_usage_little_str, cpu_usage_big_str, state_str, exec_time_str = input().split() #RECEBIMENTO DO ESTADO DA MAIN
        pmu1 = float.fromhex(pmu1_str)
        pmu2 = float.fromhex(pmu2_str)
        pmu3 = float.fromhex(pmu3_str)
        pmu4 = float.fromhex(pmu4_str)
        cpu_usage_little  = float.fromhex(cpu_usage_little_str)
        cpu_usage_big  = float.fromhex(cpu_usage_big_str)
        current_state = float(state_str)
        exec_time = float(exec_time_str)

        return np.array([pmu1, pmu2, pmu3, pmu4, cpu_usage_little, cpu_usage_big, current_state, exec_time])

    def write_to_scheduler(self, action):
        print (action)


    def save_model(self):
        model.save("ppo2_model") 



#model = PPO2(policy="MlpPolicy", tensorboard_log="./ppo2_tensorborad/",env=env,learning_rate=0.00025, lam=0.8, n_steps=30, nminibatches=1)
#model = DQN(policy="MlpPolicy", tensorboard_log="./dqn_tensorborad2/", batch_size=1, gamma=0.1, exploration_fraction=0.1, env=env)
#model.learn(total_timesteps=int(1e+4), seed=0)


env = DummyVecEnv([lambda: EnviromentExample()])
model = PPO2.load("ppo2_model.pkl")
obs = env.reset()

while True:
    action, _ = model.predict(obs)

    obs, reward, done, _ = env.step(action)
    if done:
        break


del model, env



