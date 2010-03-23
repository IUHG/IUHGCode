!-*-f90-*-     
      PROGRAM Ams
      IMPLICIT NONE

      INCLUDE 'mpif.h'
      
      INTEGER,PARAMETER :: DOUBLE = SELECTED_REAL_KIND(15,300)
      INTEGER,PARAMETER :: jmax=512,kmax=64,lmax=128
      INTEGER,PARAMETER :: start = 110200
      INTEGER,PARAMETER :: finish = 250000
      INTEGER,PARAMETER :: skip = 200
      INTEGER,PARAMETER :: size = ((finish-start)/skip)+1
      INTEGER,PARAMETER :: jstart = 90

      INTEGER :: jmax2,kmax2,mmax,amcount,process
      INTEGER :: count,j,k,l,m,i,m_return,sender
      INTEGER :: numranks,mpierr,myrank
      INTEGER :: status(MPI_STATUS_SIZE)
      REAL(DOUBLE),PARAMETER :: tconv = 1605.63
      REAL(DOUBLE),PARAMETER :: pi = 3.14159265358979323846d0
      REAL(DOUBLE),PARAMETER :: twopi = 2.d0*pi
      REAL(DOUBLE),DIMENSION(:,:,:),ALLOCATABLE    :: rho
      REAL(DOUBLE),DIMENSION(:,:),ALLOCATABLE      :: am,bm,ambmslice
      REAL(DOUBLE),DIMENSION(:,:),ALLOCATABLE      :: a0tot,a0mid,a0
      REAL(DOUBLE),DIMENSION(:),ALLOCATABLE        :: avgaslice
      REAL(DOUBLE),DIMENSION(:,:) :: avga,avgamid
      REAL(DOUBLE),DIMENSION(size) :: timearr
      REAL(DOUBLE) :: time,phi,dphi
      LOGICAL EXISTSTAT
      CHARACTER outfile*80,indir*80
      CHARACTER rhofile*80,amfile*80,filenum*8,str*80

      type answer_return
         sequence
         REAL(DOUBLE) :: a, amid
      end type answer_return

      type (answer_return) answer

      outfile = "indiram15AU.dat"
      indir = "../WAN_RHO/"

      call MPI_INIT(mpierr)
      call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, mpierr)
      call MPI_COMM_SIZE(MPI_COMM_WORLD, numranks, mpierr)

      mmax   = LMAX/2
      jmax2 = jmax+2
      kmax2 = kmax+2
      dphi  = twopi/lmax

      ALLOCATE(rho(jmax2,kmax2,lmax))
      ALLOCATE(a0tot(mmax,size))
      ALLOCATE(a0mid(mmax,size))

      avga(:,:)          = 0.d0
      avgamid(:,:)       = 0.d0
      timearr(:)         = 0.d0
      a0tot(:,:)         = 0.d0
      a0mid(:,:)         = 0.d0

      IF(myrank.eq.0) THEN

         ALLOCATE(avga(LMAX/2,size))
         ALLOCATE(avgamid(LMAX/2,size))

         count = 0
         write(filenum,'(I6.6)')start
         rhofile=trim(indir)//'rho3d.'//filenum
         OPEN(UNIT=12,FILE=trim(rhofile),FORM='UNFORMATTED')

         READ(12) rho
         READ(12) time
         CLOSE(12)

         count = count+1
         timearr(count) = time/tconv

         DO i=start,finish,skip

            AMCOUNT = 1
            
            CALL MPI_BCAST(RHO,JMAX2*KMAX2*LMAX,MPI_DOUBLE_PRECISION,&
                 0,MPI_COMM_WORLD,mpierr)

            DO PROCESS=1,min(numranks-1,mmax)
               CALL MPI_SEND(AMCOUNT,1,MPI_INTEGER,PROCESS,AMCOUNT,&
                    MPI_COMM_WORLD,mpierr)
               AMCOUNT = AMCOUNT+1
            ENDDO

911         CONTINUE

            IF(I.lt.IEND) THEN
               WRITE(filenum,'(I6.6)')i
               rhofile = indir//"rho3d."//filenum
         
               INQUIRE(FILE=rhofile,EXIST=EXISTSTAT)
         
               IF(.not.EXISTSTAT) THEN
                  print*,"file ",rhofile, "does not exist"
                  I = I+1
                  GO TO 911
               ENDIF
         
!         print*," AMS OUT -> OPENING FILE: ", rhofile
               OPEN(UNIT=12,FILE=rhofile,FORM="UNFORMATTED")

               READ(12) rho
               READ(12) time
               CLOSE(12)
         
!         print*,' AMS OUT -> READ FILE: ',rhofile
               count = count+1
               timearr(count) = time/tconv
            ENDIF

            DO PROCESS=1,MMAX+1
               call MPI_RECV(answer,2,MPI_DOUBLE_PRECISION,&
                    MPI_ANY_SOURCE,MPI_ANY_TAG,MPI_COMM_WORLD,status,&
                    mpierr)
               
               sender = status(MPI_SOURCE)
               m_return = status(MPI_TAG)

               avga(m_return,count) = answer%a
               avgamid(m_return,count) = answer%amid
               
               IF(AMCOUNT.lt.MMAX) THEN
                  call MPI_SEND(AMCOUNT,1,MPI_INTEGER,sender,AMCOUNT,&
                       MPI_COMM_WORLD,mpierr)
                  AMCOUNT = AMCOUNT+1
               ELSE
                  call MPI_SEND(MPI_BOTTOM,0,MPI_INTEGER,sender,MMAX+1,&
                       MPI_COMM_WORLD,mpierr)
               ENDIF
            ENDDO
         ENDDO

!$OMP PARALLEL DO DEFAULT(SHARED) 
!$OMP&PRIVATE(am,bm,a0,avgaslice,ambmslice,phi,j,k,l)

         DO m=1,MMAX
            ALLOCATE(a0(jmax2,kmax2))
            ALLOCATE(am(jmax2,kmax2))
            ALLOCATE(bm(jmax2,kmax2))
            ALLOCATE(ambmslice(jmax2,kmax2))
            ALLOCATE(avgaslice(kmax2))
            am(:,:)        = 0.d0
            bm(:,:)        = 0.d0
            a0(:,:)        = 0.d0
            avgaslice(:)   = 0.d0
            ambmslice(:,:) = 0.d0
            DO k=2,kmax+1
               DO j=jstart,jmax+1
                  DO l=1,lmax
                     phi = twopi*dble(l)/dble(lmax)        
                     am(j,k) = am(j,k)+rho(j,k,l)*
     &                    cos(m*phi)
                     bm(j,k) = bm(j,k)+rho(j,k,l)*
     &                    sin(m*phi)
                     a0(j,k) = a0(j,k)+rho(j,k,l)
                  ENDDO
                  ambmslice(j,k) = sqrt((am(j,k))**2+
     &                 (bm(j,k))**2)*(dble(J+1)**2-dble(J)**2)
                  avgaslice(k) = avgaslice(k)
     &                 +ambmslice(j,k)
                  a0tot(m,count) = a0tot(m,count)+a0(j,k)
     &                 *(dble(J+1)**2-dble(J)**2)
               ENDDO
               IF(K==2)THEN
                  avgamid(m,count) = avgaslice(k)
                  a0mid(m,count) = a0tot(m,count)
               ENDIF
               avga(m,count) = avga(m,count)+avgaslice(k)
            ENDDO
            DEALLOCATE(a0)
            DEALLOCATE(am)
            DEALLOCATE(bm)
            DEALLOCATE(ambmslice)
            DEALLOCATE(avgaslice)
         ENDDO
!$OMP END PARALLEL DO
      ENDDO

      avgamid(:,:) = avgamid(:,:)*2.d0/a0mid(:,:)
      avga(:,:)    = avga(:,:)*2.d0/a0tot(:,:)      
!      avga(:,:)    = LOG10(avga(:,:))
!      avgamid(:,:) = LOG10(avgamid(:,:))
!      print*,'FORTRAN COUNT = ',count

!      print*,avga(2,:)
!      print*,mmax, count

      OPEN(UNIT=12,FILE=outfile,FORM='UNFORMATTED')
      WRITE(12) mmax,count
      WRITE(12) avga
      WRITE(12) avgamid
      WRITE(12) timearr
      CLOSE(12)

      DEALLOCATE(rho)
      
      END

      
      
