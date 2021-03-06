
#This program solves quasi one dimensional nozzle flows using MacCormack Scheme
#Subsonic-Supersonic Isentropic Flow
#Governing Equations in Conservation Form
#This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
#Ao Xu, Profiles: <http://www.linkedin.com/pub/ao-xu/30/a72/a29>

import numpy as np
import matplotlib.pyplot as plt

def mac():
    n = 61
    gamma = 1.4
    dx = 3.0/(n-1)    
    
    X = np.arange(0,3+dx,dx)
    
    S = np.zeros(n)
    rho = np.zeros(n)
    Te = np.zeros(n)
    P = np.zeros(n)
    V = np.zeros(n)
    Ma = np.zeros(n)

    U1 = np.zeros(n)
    U2 = np.zeros(n) 
    U3 = np.zeros(n)

    F1 = np.zeros(n)
    F2 = np.zeros(n)
    F3 = np.zeros(n)

    dU1 = np.zeros(n)
    dU2 = np.zeros(n)
    dU3 = np.zeros(n)

    RU1 = np.zeros(n)
    RU2 = np.zeros(n)
    RU3 = np.zeros(n)
    
    for i in range(n):
        S[i] = 1+2.2*(X[i]-1.5)*(X[i]-1.5)
    
    for i in range(n):
        if 0.0 <= X[i] <= 0.5:
            rho[i] = 1.0
            Te[i] = 1.0
        elif 0.5 <= X[i] <=1.5:
            rho[i] = 1.0-0.366*(X[i]-0.5)
            Te[i] = 1.0-0.167*(X[i]-0.5)
        elif 1.5 <= X[i] <= 3.0:
            rho[i] = 0.634-0.3879*(X[i]-1.5)
            Te[i] = 0.833-0.3507*(X[i]-1.5)
    for i in range(n):
        V[i] = 0.59/rho[i]/S[i]
    for i in range(n):
        U1[i] = rho[i]*S[i]
        U2[i] = rho[i]*S[i]*V[i]
        U3[i] = rho[i]*(Te[i]/(gamma-1)+gamma/2.0*V[i]*V[i])*S[i]

    dt = 1.0
    for nt in range(1400):
        #dt
        for i in range(n-1):
            t_min = 0.5*dx/(np.sqrt(Te[i])+V[i])
            if t_min < dt:
                dt = t_min

        for i in range(n-1):
            F1[i] = U2[i]
            F2[i] = U2[i]*U2[i]/U1[i]+(gamma-1.0)/gamma*(U3[i]-gamma/2.0*U2[i]*U2[i]/U1[i])
            F3[i] = gamma*U2[i]*U3[i]/U1[i]-gamma*(gamma-1)/2.0*U2[i]*U2[i]*U2[i]/U1[i]/U1[i]
            
        #step1
        for i in range(n-1):
            dU1[i] = -(F1[i+1]-F1[i])/dx
            dU2[i] = -(F2[i+1]-F2[i])/dx+(gamma-1)/gamma*(U3[i]-gamma/2.0*U2[i]*U2[i]/U1[i])*(np.log(S[i+1])-np.log(S[i]))/dx
            dU3[i] = -(F3[i+1]-F3[i])/dx

        #step2
        for i in range(n-1):
            RU1[i] = U1[i]+dU1[i]*dt
            RU2[i] = U2[i]+dU2[i]*dt
            RU3[i] = U3[i]+dU3[i]*dt

        #step3
        for i in range(n-1):
            F1[i] = RU2[i]
            F2[i] = RU2[i]*RU2[i]/RU1[i]+(gamma-1.0)/gamma*(RU3[i]-gamma/2.0*RU2[i]*RU2[i]/RU1[i])
            F3[i] = gamma*RU2[i]*RU3[i]/RU1[i]-gamma*(gamma-1)/2.0*RU2[i]*RU2[i]*RU2[i]/RU1[i]/RU1[i]

        for i in range(1,n-1):
            dRU1 = -(F1[i]-F1[i-1])/dx
            dRU2 = -(F2[i]-F2[i-1])/dx+(gamma-1)/gamma*(RU3[i]-gamma/2.0*RU2[i]*RU2[i]/RU1[i])*(np.log(S[i])-np.log(S[i-1]))/dx
            dRU3 = -(F3[i]-F3[i-1])/dx
        #step4
            dU1_av = 0.5*(dU1[i]+dRU1)
            dU2_av = 0.5*(dU2[i]+dRU2)
            dU3_av = 0.5*(dU3[i]+dRU3)
        #step5
            U1[i] = U1[i]+dU1_av*dt
            U2[i] = U2[i]+dU2_av*dt
            U3[i] = U3[i]+dU3_av*dt

        #B.C.
        U1[0] = S[0]
        U2[0] = 2*U2[1]-U2[2]
        V[0] = U2[0]/U1[0]
        U3[0] = U1[0]*(Te[0]/(gamma-1)+gamma/2.0*V[0]*V[0])

        U1[n-1] = 2*U1[n-2]-U1[n-3]
        U2[n-1] = 2*U2[n-2]-U2[n-3]
        U3[n-1] = 2*U3[n-2]-U3[n-3]

        for i in range(n):
            rho[i] = U1[i]/S[i]
            V[i] = U2[i]/U1[i]
            Te[i] = (gamma-1)*(U3[i]/U1[i]-gamma/2.0*V[i]*V[i])
            P[i] = rho[i]*Te[i]

    for i in range(n):
            P[i] = rho[i]*Te[i]
            Ma[i] = V[i]/np.sqrt(Te[i])

#Show results
    plt.plot(X,rho,'ro-',label="Numerical Solution",linewidth=1)
    #plt.plot(X,pre_rho,'k--',label="Exact Solution")
    plt.xlabel(r'$X$')
    plt.ylabel(r'$\rho$')   
    plt.title('Quasi One_Dimensional Nozzle Flows'+'(Density)')
    plt.legend(prop={"size":12})
    plt.savefig('2_rho')
    plt.show()

    plt.plot(X,Te,'ro-',label="Numerical Solution",linewidth=1)
    #plt.plot(X,pre_Te,'k--',label="Exact Solution")
    plt.xlabel(r'$X$')
    plt.ylabel(r'$T$')   
    plt.title('Quasi One_Dimensional Nozzle Flows'+'(Temperature)')
    plt.legend(prop={"size":12})
    plt.savefig('2_T')
    plt.show()

    plt.plot(X,P,'ro-',label="Numerical Solution",linewidth=1)
    #plt.plot(X,pre_Te,'k--',label="Exact Solution")
    plt.xlabel(r'$X$')
    plt.ylabel(r'$P$')   
    plt.title('Quasi One_Dimensional Nozzle Flows'+'(Pressure)')
    plt.legend(prop={"size":12})
    plt.savefig('2_P')
    plt.show()

    plt.plot(X,Ma,'ro-',label="Numerical Solution",linewidth=1)
    #plt.plot(X,pre_V,'k--',label="Exact Solution")
    plt.xlabel(r'$X$')
    plt.ylabel(r'$Ma$')   
    plt.title('Quasi One_Dimensional Nozzle Flows'+'(Mach number)')
    plt.legend(prop={"size":12})
    plt.savefig('2_Ma')
    plt.show()
    
    return

    
def main():
    print 'This program solves quasi one dimensional nozzle flows using MacCormack Scheme'
    print 'Subsonic-Supersonic Isentropic Flow'
    print 'Governing Equations in Conservation Form'
    mac()
    print 'End!'


if __name__=='__main__':
    main()
