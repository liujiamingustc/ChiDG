!> Chimera-based, discontinuous Galerkin equation solver
!!
!! This program is designed to solve partial differential equations,
!! and systems of partial differential equations, using the discontinuous
!! Galerkin method for spatial discretization using Chimera, overset grids to
!! represent the simulation domain.
!!
!! @author Nathan A. Wukie



program driver
    use mod_kinds,              only: rk, ik
    use mod_constants,          only: XI_MIN, XI_MAX, ETA_MIN, ETA_MAX, ZETA_MIN, ZETA_MAX, ONE, TWO, THREE, FOUR, FIVE, ZERO
    use type_chidg,             only: chidg_t
    use type_point,             only: point_t
    use mod_hdfio,              only: read_grid_hdf
    use mod_grid_operators,     only: initialize_variable
    use atype_function,         only: function_t
    use type_dict,              only: dict_t
    use mod_function,           only: create_function
    use mod_tecio,              only: write_tecio_variables
    use mod_testutils,          only: meshgen
    use mod_io
    
    !-----------------------------------------------------------
    ! Variable declarations
    !-----------------------------------------------------------
    implicit none
    type(chidg_t)                       :: chidg
    type(point_t),          allocatable :: pts(:,:,:)
    class(function_t),      allocatable :: constant, vortex
    type(dict_t)                        :: toptions
    integer(ik)                         :: nterms_c 



    !
    ! Initialize ChiDG environment
    !
    call chidg%init('env')
    call chidg%init('io')


    !
    ! Initialize grid and numerics
    !
    call read_grid_hdf(gridfile,chidg%domains)
    !call meshgen('15x15x2',pts)
    !call chidg%set('ndomains','')
    !nterms_c = 8
    !call chidg%domains(1)%init_geom(nterms_c,pts)


    !
    ! Set time-scheme options
    !
    call toptions%set('dt',dt)
    call toptions%set('tol',ttol)
    call toptions%set('nsteps',nsteps)
    call toptions%set('nwrite',nwrite)

    !
    ! Set ChiDG components
    !
    call chidg%set('time_scheme',timescheme,toptions)
    call chidg%set('matrixsolver',matrixsolver)



    associate ( dom => chidg%domains(1) )
        !
        ! Initialize domain
        !
        call dom%init_bc('euler_totalinlet',XI_MIN)
        call dom%init_bc('euler_pressureoutlet',XI_MAX)
        !call dom%init_bc('euler_wall',XI_MIN)
        !call dom%init_bc('euler_wall',XI_MAX)
        call dom%init_bc('euler_wall',ETA_MIN)
        call dom%init_bc('euler_wall',ETA_MAX)
        call dom%init_bc('euler_wall',ZETA_MIN)
        call dom%init_bc('euler_wall',ZETA_MAX)

        call dom%init_sol(eqnset,nterms_s)

        !
        ! Initialize solution
        !
        call create_function(constant,'constant')
        
        call constant%set('val',1._rk)
        call initialize_variable(dom,1,constant)
        call constant%set('val',1._rk)
        call initialize_variable(dom,2,constant)
        call constant%set('val',ZERO)
        call initialize_variable(dom,3,constant)
        call constant%set('val',ZERO)
        call initialize_variable(dom,4,constant)
        call constant%set('val',13.5023_rk)
        call initialize_variable(dom,5,constant)

    end associate

    !
    ! Write initial solution
    !
    call write_tecio_variables(chidg%domains(1),'0.plt',1)



    
    !
    ! Wrap-up initialization activities
    !
    call chidg%init('finalize')





    !
    ! Run ChiDG simulation
    !
    call chidg%run()






end program driver
