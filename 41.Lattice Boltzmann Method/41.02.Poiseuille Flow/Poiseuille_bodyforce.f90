
!!!    This program sloves Tube Flow problem using Lattice Boltzmann Method
!!!    Copyright (C) 2013  Ao Xu
!!!    This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License.
!!!    Ao Xu, Profiles: <http://www.linkedin.com/pub/ao-xu/30/a72/a29>


!!!                        Stationary Wall
!!!               |------------------------------|
!!!               |                              |
!!!               |                              |  Periodic Boundary
!!!               |                              |
!!!               |                              |  driven by body force
!!!               |                              |
!!!               |                              |
!!!               |------------------------------|
!!!                       Stationary Wall


        program main
        implicit none
        integer, parameter :: N=5,M=5
        integer :: i, j, itc, itc_max, k
        integer :: mid_x, mid_y
        real(8) :: c, dx, dy, tau,  dt, nu
        real(8) :: F_body
        real(8) :: eps, error
        real(8) :: X(N), Y(M), u(N,M), v(N,M), up(N,M), vp(N,M), rho(N,M), p(N,M)
        real(8) :: omega(0:8), f(0:8,N,M), un(0:8),gx(0:8)
        real(8) :: ex(0:8), ey(0:8)
        character (len=100):: filename
        data ex/0.0d0,1.0d0,0.0d0, -1.0d0, 0.0d0, 1.0d0, -1.0d0, -1.0d0, 1.0d0/
        data ey/0.0d0,0.0d0,1.0d0, 0.0d0, -1.0d0, 1.0d0, 1.0d0, -1.0d0, -1.0d0/

!!!     D2Q9 Lattice Vector Properties:
!!!              6   2   5
!!!                \ | /
!!!              3 - 0 - 1
!!!                / | \
!!!              7   4   8

!!! input initial data

        dx = 1.0d0/float(N-1)
        dy = 1.0d0/float(M-1)

        tau = 3.0d0
        nu = 0.01d0
        dt = (2.0d0*tau-1.0d0)*dx*dx/6.0d0/nu
        c = dx/dt

        ex = c*ex
        ey = c*ey

        F_body = 1e-3
        gx(0) = 0.0d0
        do i=1,4
            gx(i) = 1.0d0/3.0d0/c*ex(i)*F_body
        enddo
        do i=5,6
            gx(i) = 1.0d0/12.0d0/c*ex(i)*F_body
        enddo

        itc = 0
        itc_max = 10000
        eps = 1e-6
        k = 0
        error = 100.0d0

!!! set up initial flow field
        call initial(N,M,dx,dy,X,Y,u,v,rho,c,omega,ex,ey,un,f)

        !do while((error.GT.eps).AND.(itc.LT.itc_max))
        do while(itc.LT.itc_max)

!!! streaming step
            call streaming(N,M,f)

!!! boundary condition
            call bounceback(N,M,f)

!!! collision step
            call collision(N,M,u,v,ex,ey,rho,f,omega,c,tau,gx,dx,dt)

!!! check convergence
            call check(N,M,u,v,up,vp,itc,error)

!!! output preliminary results
            if(MOD(itc,10000).EQ.0) then
                call calp(N,M,c,rho,p)
                k = k+1
                call output(N,M,X,Y,up,vp,p,k)
            endif

        enddo

!!! compute pressure field
        call calp(N,M,c,rho,p)

!!! output data file
        k = k+1
        call output(N,M,X,Y,up,vp,p,k)

        write(filename,*) tau
        filename = adjustl(filename)

        open(unit=02,file='u-y_tau'//trim(filename)//'.dat',status='unknown')
        write(02,101)
        write(02,202)
        write(02,203) M

        mid_x = (N-1)/2+1
        mid_y = (M-1)/2+1

        do j=1,M
                write(02,100)  up(mid_x,j), Y(j)
        enddo

        write(*,*)
        write(*,*) '************************************************************'
	write(*,*) 'nu=',nu
        write(*,*) 'tau=',tau
        write(*,*) 'c=',c
        write(*,*) 'u(mid_x,mid_y)', up(mid_x,mid_y)
        write(*,*) '************************************************************'
        write(*,*)

100     format(2x,10(e12.6,'      '))
101     format('Title="Poiseuille Flow"')
202     format('Variables=U,Y')
203     format('zone',1x,'i=',1x,i5,2x,'f=point')

        close(02)

        stop
        end program main

!!! set up initial flow field
        subroutine initial(N,M,dx,dy,X,Y,u,v,rho,c,omega,ex,ey,un,f)
        implicit none
        integer :: N, M, i, j
        integer :: alpha
        real(8) :: dx, dy
        real(8) :: c, us2
        real(8) :: X(N), Y(M)
        real(8) :: omega(0:8), u(N,M), v(N,M), rho(N,M), ex(0:8), ey(0:8), un(0:8)
        real(8) :: f(0:8,N,M)


        do i=1,N
            X(i) = (i-1)*dx
        enddo
        do j=1,M
            Y(j) = (j-1)*dy
        enddo

        omega(0) = 4.0d0/9.0d0
        do alpha=1,4
            omega(alpha) = 1.0d0/9.0d0
        enddo
        do alpha=5,8
            omega(alpha) = 1.0d0/36.0d0
        enddo


        u = 0.0d0
        v = 0.0d0
        rho = 1.0d0

        do i=1,N
            do j=1,M
                us2 = u(i,j)*u(i,j)+v(i,j)*v(i,j)
                do alpha=0,8
                    un(alpha) = u(i,j)*ex(alpha)+v(i,j)*ey(alpha)
                    f(alpha,i,j) = omega(alpha) &
                    *(1.0d0+3.0d0*un(alpha)/c/c+9.0d0*un(alpha)*un(alpha)/2.0d0/c/c/c/c-3.0d0*us2/2.0d0/c/c)
                enddo
            enddo
        enddo

        return
        end subroutine initial

!!! streaming step
        subroutine streaming(N,M,f)
        implicit none
        integer :: i, j, N, M
        real(8) :: f(0:8,N,M)



        do i=1,N
            do j=1,M
                f(0,i,j) = f(0,i,j)
            enddo
        enddo
        do i=N,2,-1
            do j=1,M
                f(1,i,j) = f(1,i-1,j)
            enddo
        enddo
        do i=1,N
            do j=M,2,-1
                f(2,i,j) = f(2,i,j-1)
            enddo
        enddo
        do i=1,N-1
            do j=1,M
                f(3,i,j) = f(3,i+1,j)
            enddo
        enddo
        do i=1,N
            do j=1,M-1
                f(4,i,j) = f(4,i,j+1)
            enddo
        enddo
        do i=N,2,-1
            do j=M,2,-1
                f(5,i,j) = f(5,i-1,j-1)
            enddo
        enddo
        do i=1,N-1
            do j=M,2,-1
                f(6,i,j) = f(6,i+1,j-1)
            enddo
        enddo
        do i=1,N-1
            do j=1,M-1
                f(7,i,j) = f(7,i+1,j+1)
            enddo
        enddo
        do i=N,2,-1
            do j=1,M-1
                f(8,i,j) = f(8,i-1,j+1)
            enddo
        enddo

        !Periodic boundary conditon
        do j=1,M
            f(1,1,j) = f(1,N,j)
            f(5,1,j) = f(5,N,j)
            f(8,1,j) = f(8,N,j)

            f(3,N,j) = f(3,1,j)
            f(6,N,j) = f(6,1,j)
            f(7,N,j) = f(7,1,j)
        enddo

        return
        end subroutine streaming


!!! boundary condition
        subroutine bounceback(N,M,f)
        implicit none
        integer :: N, M, i, j
        real(8) :: f(0:8,N,M)

        do i=1,N

            !Bottom side
            f(2,i,1) = f(4,i,1)
            f(5,i,1) = f(7,i,1)
            f(6,i,1) = f(8,i,1)

            !Up side
            f(4,i,M) = f(2,i,M)
            f(7,i,M) = f(5,i,M)
            f(8,i,M) = f(6,i,M)

        enddo


        return
        end subroutine bounceback

!!! collision step
        subroutine collision(N,M,u,v,ex,ey,rho,f,omega,c,tau,gx,dx,dt)
        implicit none
        integer :: N, M, i, j
        integer :: alpha
        real(8) :: dx, dt
        real(8) :: c, tau
        real(8) :: us2
        real(8) :: u(N,M), v(N,M), ex(0:8), ey(0:8), rho(N,M), f(0:8,N,M), omega(0:8)
        real(8) :: un(0:8), feq(0:8,N,M)
        real(8) :: gx(0:8)

        do i=1,N
            do j=1,M

                    rho(i,j) = 0.0d0
                    do alpha=0,8
                        rho(i,j) = rho(i,j)+f(alpha,i,j)
                    enddo

                    !data ex/0.0d0,1.0d0,0.0d0, -1.0d0, 0.0d0, 1.0d0, -1.0d0, -1.0d0, 1.0d0/
                    !data ey/0.0d0,0.0d0,1.0d0, 0.0d0, -1.0d0, 1.0d0, 1.0d0, -1.0d0, -1.0d0/
                    u(i,j) = c*(f(1,i,j)-f(3,i,j)+f(5,i,j)-f(6,i,j)-f(7,i,j)+f(8,i,j))/rho(i,j)
                    v(i,j) = c*(f(2,i,j)-f(4,i,j)+f(5,i,j)+f(6,i,j)-f(7,i,j)-f(8,i,j))/rho(i,j)
                    us2 = u(i,j)*u(i,j)+v(i,j)*v(i,j)
                    do alpha=0,8
                        un(alpha) = u(i,j)*ex(alpha) + v(i,j)*ey(alpha)
                        feq(alpha,i,j) = omega(alpha)*rho(i,j) &
                                *(1.0d0+3.0d0*un(alpha)/c/c+9.0d0*un(alpha)*un(alpha)/2.0d0/c/c/c/c-3.0d0*us2/2.0d0/c/c)
                        f(alpha,i,j) = f(alpha,i,j)-1.0d0/tau*(f(alpha,i,j)-feq(alpha,i,j))+gx(alpha)*dt*dt/dx
                    enddo
            enddo
        enddo

        !Left bottom corner
        f(6,1,1) = feq(6,1,1)
        f(8,1,1) = feq(8,1,1)

        !Left up corner
        f(5,1,M) = feq(5,1,M)
        f(7,1,M) = feq(7,1,M)

        !Right bottom corner
        f(5,N,1) = feq(5,N,1)
        f(7,N,1) = feq(7,N,1)

        !Right up corner
        f(6,N,M) = feq(6,N,M)
        f(8,N,M) = feq(8,N,M)

        return
        end subroutine collision


!!! check convergence
        subroutine check(N,M,u,v,up,vp,itc,error)
        implicit none
        integer :: N, M, i, j
        integer :: alpha
        integer :: itc
        real(8) :: error
        real(8) :: u(N,M), v(N,M), up(N,M), vp(N,M)

        itc = itc+1
        error = 0.0d0
        if(itc.EQ.1) error = 10.0d0
        if(itc.EQ.2) error = 10.0d0
        if(itc.EQ.3) error = 10.0d0

        if(itc.GT.3) then
            do i=1,N
                do j=1,M
                        error  = error+SQRT((u(i,j)-up(i,j))*(u(i,j)-up(i,j))+(v(i,j)-vp(i,j))*(v(i,j)-vp(i,j))) &
                                        /SQRT((u(i,j)+0.000001)*(u(i,j)+0.000001)+(v(i,j)+0.00001)*(v(i,j)+0.000001))
                enddo
            enddo
        endif

        up = u
        vp = v

        if(MOD(itc,50).EQ.0) write(*,*) itc,' ',error

!        open(unit=01,file='error.dat',status='unknown',position='append')
!        if (MOD(itc,2000).EQ.0) then
!            write(01,*) itc,' ',error
!        endif
!        close(01)

        return
        end subroutine check

!!! compute pressure field
        subroutine calp(N,M,c,rho,p)
        implicit none
        integer :: N, M, i, j
        real(8) :: c
        real(8) :: rho(N,M), p(N,M)

        do i=1,N
            do j=1,M
                p(i,j) = rho(i,j)*c*c/3.0d0
            enddo
        enddo

        return
        end subroutine calp

!!! output data file
        subroutine output(N,M,X,Y,up,vp,p,k)
        implicit none
        integer :: N, M, i, j, k
        real(8) :: X(N), Y(M), up(N,M), vp(N,M), p(N,M)
        character (len=100):: filename

        write(filename,*) k
        filename = adjustl(filename)
        open(unit=02,file='output_'//trim(filename)//'.dat',status='unknown')

        write(02,101)
        write(02,102)
        write(02,103) N, M

        do j=1,M
            do i=1,N
                write(02,100) X(i), Y(j), up(i,j), vp(i,j)!, p(i,j)
            enddo
        enddo

100     format(2x,10(e12.6,'      '))
101     format('Title="Poiseuille Flow"')
102     format('Variables=x,y,u,v')
103     format('zone',1x,'i=',1x,i5,2x,'j=',1x,i5,1x,'f=point')

        close(02)

        return
        end subroutine output

