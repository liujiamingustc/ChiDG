module mod_project
    use mod_kinds,          only: rk,ik
    use mod_quadrature,     only: GQ, get_quadrature, compute_nnodes_gq
    use mod_grid_tools,     only: compute_discrete_coordinates
    use type_point,         only: point_t
    use type_densevector,   only: densevector_t
    use type_function,      only: function_t

    implicit none



contains



    !>  Project values from a function evaluation to the polynomial basis
    !!
    !!  @author Nathan A. Wukie
    !!
    !!  @param[in]  fcn         Incoming function to evaluate. Arguments should be in cartesian coordinates(x, y, z).
    !!  @param[in]  spacedim    Number of spatial dimensions in the expansions
    !!  @param[in]  nterms      Number of terms in the basis being projected to
    !!  @param[in]  cmodes      Modal coefficients of coordinate expansion to evaluate cartesian coordinates
    !!  @param[out] fmodes      Modal coefficients of the projected function
    !!
    !-----------------------------------------------------------------------------------------------------------------
    subroutine project_function_xyz(fcn,spacedim,nterms,cmodes,fmodes)
        class(function_t),      intent(inout)   :: fcn
        integer(ik),            intent(in)      :: spacedim
        integer(ik),            intent(in)      :: nterms
        type(densevector_t),    intent(in)      :: cmodes           ! Expansion contains x-modes, y-modes, and z-modes
        real(rk),               intent(inout)   :: fmodes(:)

        type(point_t),  allocatable     :: pts(:)
        real(rk),       allocatable     :: fvals(:)
        real(rk)                        :: time
        integer(ik)                     :: nterms_1d, nn_face, nn_vol, igq, ierr, i
        integer(ik)                     :: gq_p, gq_c
        logical                         :: has_correct_nodes_terms


        !
        ! Compute number of face and volume quadrature nodes
        !
        call compute_nnodes_gq(spacedim,nterms,cmodes%nterms(),nn_face,nn_vol)


        !
        ! Find the correct quadrature instance for projecting the function values
        ! and for evaluating the coordinates at discrete points.
        !
        call get_quadrature(spacedim,nterms,nn_vol,nn_face,gq_p)
        call get_quadrature(spacedim,cmodes%nterms(),nn_vol,nn_face,gq_c)


        !
        ! Compute discrete cartesian coordinates
        !
        allocate(pts(nn_vol), fvals(nn_vol), stat=ierr)
        if (ierr /= 0) stop "Error: project_function_xyz -- allocation error"
        call compute_discrete_coordinates(cmodes,gq_c,pts)


        !
        ! Call function for evaluation and multiply by quadrature weights
        !
        time  = 0._rk
        fvals = fcn%compute(time,pts)  *  GQ(gq_p)%vol%weights


        !
        ! Project
        !
        fmodes = matmul(transpose(GQ(gq_p)%vol%val),fvals) / GQ(gq_p)%vol%dmass

    end subroutine project_function_xyz
    !****************************************************************************************************************














end module mod_project
