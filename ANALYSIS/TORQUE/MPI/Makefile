#-*-Makefile-*-
# makefile for the 3-D astrophysical hydrodynamics code.

 #MAKEFILE = Makefile.intel

#===============================================================================
 TARCH      = -r8 -mtune=core2 -mcmodel=medium -convert big_endian

 OMPF95     = mpif90

 F90FLAGS   = -O3 -pad -align all -nocheck -fast -shared-intel -openmp -fixed

 LINKFLAGS  = -O3 -pad -align all -nocheck -shared-intel -openmp -fixed

 LIBS       = $(LINKFLAGS) $(TARCH)

# C compilers
 CC         = icc

 .f.o:
	$(OMPF95) $(F90FLAGS) -c $*.f

 OBJ = fft.o dcomp.o blktri.o torqueout.o boundary.o

#===============================================================================
#                        EXECUTABLES

decompose: dummy
	make target "FC=$(OMPF95)" "CC=$(CC)" \
 "CFLAGS=$(F90FLAGS) $(TARCH)" "TARGET = decompose"

#-------------------------------------------------------------------------------
target: $(OBJ) $(PERFOBJ) $(DBGOBJ)
	$(FC) $(LIBS) -o $(TARGET) $(OBJ)

dummy:

clean:
	rm -f *.o decompose


#===============================================================================
#                          OBJECTS

fft.o: fft.f
	$(FC) $(CFLAGS) -c $<

dcomp.o: dcomp.f
	$(FC) $(CFLAGS) -c dcomp.f

blktri.o: blktri.f
	$(FC) $(CFLAGS) -c $<

torqueout.o: torqueout.F
	$(FC) $(CFLAGS) -c $<

boundary.o: boundary.f
	$(FC) $(CFLAGS) -c $<
