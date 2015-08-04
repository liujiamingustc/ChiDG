module mod_integrate
    use mod_kinds,          only: rk,ik
    use type_element,       only: element_t
    use type_face,          only: face_t
    use type_expansion,     only: expansion_t
    use atype_solver,       only: solver_t
    use type_blockmatrix,   only: blockmatrix_t
    use DNAD_D


    implicit none



contains



    !>  Compute the volume integral of a flux vector
    !!
    !!      - Adds value contribution to the rhs vector
    !!      - Adds the derivative contribution to the linearization matrix
    !!
    !!  @author Nathan A. Wukie
    !!  @param[in]      elem    Element being integrated over
    !!  @param[inout]   rhs     Right-hand side vector storage
    !!  @param[inout]   lin     Domain linearization matrix
    !!  @param[in]      iblk    Selected block of the linearization being computed. lin(ielem,iblk), where iblk = (1-7)
    !!  @param[in]      ivar    Index of the variable associated with the flux being integrated
    !!  @param[inout]   flux_x  x-Flux and derivatives at quadrature points
    !!  @param[inout]   flux_y  y-Flux and derivatives at quadrature points
    !!  @param[inout]   flux_z  z-Flux and derivatives at quadrature points
    !--------------------------------------------------------------------------------------------------------
    subroutine integrate_volume_flux(elem,solver,ivar,iblk,flux_x,flux_y,flux_z)
        type(element_t),        intent(in)      :: elem
        class(solver_t),        intent(inout)   :: solver
!        type(expansion_t),      intent(inout)   :: rhs(:)
!        type(blockmatrix_t),    intent(inout)   :: lin
        integer(ik),            intent(in)      :: ivar
        integer(ik),            intent(in)      :: iblk
        type(AD_D),             intent(inout)   :: flux_x(:), flux_y(:), flux_z(:)


        integer(ik)                             :: ielem
        type(AD_D), dimension(elem%nterms_s)    :: integral

        ielem = elem%ielem  !> get element index

        ! Multiply each component by quadrature weights and element jacobians
        flux_x = (flux_x) * (elem%gq%vol%weights) * (elem%jinv)
        flux_y = (flux_y) * (elem%gq%vol%weights) * (elem%jinv)
        flux_z = (flux_z) * (elem%gq%vol%weights) * (elem%jinv)

        ! FLUX-X
        ! Multiply by column of test function gradients, integrate, add to RHS, add derivatives to linearization
        integral = matmul(transpose(elem%dtdx),flux_x)                          !> Integrate
        call store_volume_integrals(integral,solver,ielem,ivar,iblk)            !> Store values and derivatives


        ! FLUX-Y
        ! Multiply by column of test function gradients, integrate, add to RHS, add derivatives to linearization
        integral = matmul(transpose(elem%dtdy),flux_y)                          !> Integrate
        call store_volume_integrals(integral,solver,ielem,ivar,iblk)            !> Store values and derivatives


        ! FLUX-Z
        ! Multiply by column of test function gradients, integrate, add to RHS, add derivatives to linearization
        integral = matmul(transpose(elem%dtdz),flux_z)                          !> Integrate
        call store_volume_integrals(integral,solver,ielem,ivar,iblk)            !> Store values and derivatives


    end subroutine








    !>  Compute the volume integral of a flux vector
    !!
    !!      - Adds value contribution to the rhs vector
    !!      - Adds the derivative contribution to the linearization matrix
    !!
    !!  @author Nathan A. Wukie
    !!  @param[in]      face    Face being integrated over
    !!  @param[inout]   rhs     Right-hand side vector storage
    !!  @param[inout]   lin     Domain linearization matrix
    !!  @param[in]      iblk    Selected block of the linearization being computed. lin(ielem,iblk), where iblk = (1-7)
    !!  @param[in]      ivar    Index of the variable associated with the flux being integrated
    !!  @param[inout]   flux_x  x-Flux and derivatives at quadrature points
    !!  @param[inout]   flux_y  y-Flux and derivatives at quadrature points
    !!  @param[inout]   flux_z  z-Flux and derivatives at quadrature points
    !--------------------------------------------------------------------------------------------------------
    subroutine integrate_boundary_flux(face,solver,ivar,iblk,flux_x,flux_y,flux_z)
        type(face_t),           intent(in)      :: face
        class(solver_t),        intent(inout)   :: solver
!        type(expansion_t),      intent(inout)   :: rhs(:)
!        type(blockmatrix_t),    intent(inout)   :: lin
        integer(ik),            intent(in)      :: ivar
        integer(ik),            intent(in)      :: iblk
        type(AD_D),             intent(inout)   :: flux_x(:), flux_y(:), flux_z(:)


        integer(ik)                             :: ielem, iface
        type(AD_D), dimension(face%nterms_s)    :: integral

        iface = face%iface
        ielem = face%iparent  !> get parent element index


        associate ( weights => face%gq%face%weights(:,iface), jinv => face%jinv, val => face%gq%face%val(:,:,iface) )

            ! Multiply each component by quadrature weights. The fluxes have already been multiplied by norm
            flux_x = (flux_x) * (weights)
            flux_y = (flux_y) * (weights)
            flux_z = (flux_z) * (weights)


            integral = matmul(transpose(val),flux_x)
            call store_boundary_integrals(integral,solver,ielem,ivar,iblk)

            integral = matmul(transpose(val),flux_y)
            call store_boundary_integrals(integral,solver,ielem,ivar,iblk)

            integral = matmul(transpose(val),flux_z)
            call store_boundary_integrals(integral,solver,ielem,ivar,iblk)

        end associate

    end subroutine







    !> Store volume integral values to RHS vector, and partial derivatives to LIN block matrix
    !!
    !!  @author Nathan A. Wukie
    !!  @param[in]      integral    Array of autodiff values containing integrals and partial derivatives for the RHS vector and LIN linearization matrix
    !!  @param[inout]   rhs         Right-hand side vector
    !!  @param[inout]   lin         Block matrix storing the linearization of the spatial scheme
    !!  @param[in]      ielem       Element index for applying to the correct location in RHS and LIN
    !!  @param[in]      ivar        Variable index
    !!  @param[in]      iblk        Block index for the correct linearization block for the current element
    !!
    !--------------------------------------------------------------------------------------------------------
    subroutine store_volume_integrals(integral,solver,ielem,ivar,iblk)
        type(AD_D),             intent(in)      :: integral(:)
        class(solver_t),        intent(inout)   :: solver
!        type(expansion_t),      intent(inout)   :: rhs(:)
!        type(blockmatrix_t),    intent(inout)   :: lin
        integer(ik),            intent(in)      :: ielem
        integer(ik),            intent(in)      :: ivar
        integer(ik),            intent(in)      :: iblk


        associate ( rhs => solver%rhs, lin => solver%lin)

            rhs(ielem)%mat(:,ivar) = rhs(ielem)%mat(:,ivar) + integral(:)%x_ad_     !> Store values
            call lin%store(integral,ielem,iblk,ivar)                                !> Store derivatives

        end associate
    end subroutine





    !> Store boundary integral values to RHS vector, and partial derivatives to LIN block matrix
    !!
    !!  @author Nathan A. Wukie
    !!  @param[in]      integral    Array of autodiff values containing integrals and partial derivatives for the RHS vector and LIN linearization matrix
    !!  @param[inout]   rhs         Right-hand side vector
    !!  @param[inout]   lin         Block matrix storing the linearization of the spatial scheme
    !!  @param[in]      ielem       Element index for applying to the correct location in RHS and LIN
    !!  @param[in]      ivar        Variable index
    !!  @param[in]      iblk        Block index for the correct linearization block for the current element
    !!
    !--------------------------------------------------------------------------------------------------------
    subroutine store_boundary_integrals(integral,solver,ielem,ivar,iblk)
        type(AD_D),             intent(in)      :: integral(:)
        class(solver_t),        intent(inout)   :: solver
!        type(expansion_t),      intent(inout)   :: rhs(:)
!        type(blockmatrix_t),    intent(inout)   :: lin
        integer(ik),            intent(in)      :: ielem
        integer(ik),            intent(in)      :: ivar
        integer(ik),            intent(in)      :: iblk

        associate ( rhs => solver%rhs, lin => solver%lin)

            rhs(ielem)%mat(:,ivar) = rhs(ielem)%mat(:,ivar) - integral(:)%x_ad_     !> Store values
            call lin%store(integral,ielem,iblk,ivar)                                !> Store derivatives

        end associate

    end subroutine






end module mod_integrate
