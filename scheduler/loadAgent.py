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
total_observation_space = 18
index_state= total_observation_space - 2
index_exec_time= total_observation_space - 1

map_action_state = [3, 7, 23]

ref_arquivo = open("Output.txt","w", buffering=1)


class EnviromentExample(Env):    
    def __init__(self):
        self.action_space = Discrete(num_actions)
        self.observation_space = Box(low=-1, high=100000, shape=(total_observation_space,))
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

        config_action = map_action_state[action]

        item = "A"+ str(self.num_steps) + ":" + str(config_action) 
        self.action_list.append(item)


        done = int(self.state[index_state]) == -1  #Sinaliza que a execução da aplicação acabou
        if done:
           self.episodes += 1

           reward = self.get_final_reward()

           #ref_arquivo.write(str(self.action_list))
           ref_arquivo.write("\n" + "Exec_time:" + str(self.state[index_exec_time]) + " Episodio:" + str(self.episodes) \
			     +  " Reward:" +  str(reward) + " Steps:" + str(self.num_steps) + " " + str(self.action_list) +  "\n")
           ref_arquivo.write("\n")

           if self.episodes == 1500:
              self.save_model()
              ref_arquivo.write("Total timesteps:" + str(self.total_time_steps) + "\n")
              ref_arquivo.close()


           self.write_to_scheduler(a) #Escrevendo a última ação do episódio para o escalonador


        else:
           reward = self.get_immediate_reward()
	
	   output=""
           for value_state in range(total_observation_space):
                aux1 = "str(\"{0:.2f}\".format(self.state["   
                aux2 = "])) + \"  \" + "
                sample = aux1 + str(value_state) + aux2
                output += sample
		
	   output = output[:-6] + " Action:" + str(config_action) + "\\n" + "\""
           ref_arquivo.write(output) 
	
           self.write_to_scheduler(config_action) 
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

	return np.array([L_pmu1, L_pmu2, L_pmu3, L_pmu4, L_pm5, \
			 B_pmu1, B_pmu2, B_pmu3, B_pmu4, B_pmu5,B_pmu6, B_pmu7, \
			 cpu_migration, context_switch, cpu_usage_little, cpu_usage_big, num_little, num_big, exec_time])

	
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



