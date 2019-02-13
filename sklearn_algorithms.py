import numpy as np 
from sklearn import model_selection
from sklearn.externals import joblib
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import ElasticNet
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.neighbors import KNeighborsRegressor


headers = ['MPKI', 'BranchMisses', 'IPC', 'N_BIGS', 'N_LITTLES', 'MIPS']
data = np.loadtxt("dataset.csv", delimiter=",")

X = data[:, 0:(len(headers) - 1)]  # Dados
Y = data[:, (len(headers) - 1)]  # Resultados


#Here the rules is 80% train and 20% test
def main():
    models = [("Linear_Regression", LinearRegression()),
              ("Elastic_Net", ElasticNet(alpha=0.001)), 
              ("Decision_Tree_Regressor", DecisionTreeRegressor()), 
              ('KNN_Regressor', KNeighborsRegressor(n_neighbors=1)),
              ("Random_Forest_Regressor", RandomForestRegressor(n_estimators=500, oob_score=True, random_state=0,n_jobs=-1)), 
              ("Gradiente_Boosting_Regressor", GradientBoostingRegressor(n_estimators=10000, learning_rate = 0.99, random_state=0))
             ]
 

    X_train, X_test, Y_train, Y_test = model_selection.train_test_split(X, Y,test_size=0.2,random_state=1)    

    for name, model in models:
        model = model
        model.fit(X_train, Y_train)
        Y_pred = model.predict(X_test)

        acum=0
        cont=0
        for i in range(len(X_test)):
            if(Y_test[i] != 0):
                acum = acum + (abs(Y_test[i]-Y_pred[i])/Y_test[i])
                cont = cont+1
				
        print(name," MeanAbsolutePercentageError:%.2f" % (100*(acum/cont)))
		
        joblib.dump(model, name+".pkl")




if __name__ == "__main__":
    main()


