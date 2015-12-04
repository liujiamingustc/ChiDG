!> Data type for storing the dense block matrices for the linearization of each element
!!  @author Nathan A. Wukie
module type_densematrix
#include <messenger.h>
    use mod_kinds,  only: rk,ik
    implicit none

    type, public :: densematrix_t
        !> block associativity
        !! Domain-global index of the element, with which this block is associated.
        !! For example, a given element has linearization blocks xi_min,xi_max,eta_min, etc.
        !! Below, we consider the linearization of element #6.
        !!
        !!   elem #5         elem #6         elem #7
        !!
        !!  blk_ximin       blk_diag        blk_ximax
        !!
        !!  The value of parent_ for the blocks would be:
        !! - blk_ximin = 5
        !! - blk_diag  = 6
        !! - blk_ximax = 7
        !!
        !! ZERO VALUE INDICATES UNASSIGNED
        integer(ik), private    :: dparent_ = 0 !> parent domain    For chimera reference accross domains
        integer(ik), private    :: eparent_ = 0  !> parent element

        !> Block storage
        !! NOTE: Assumes square blocks, since this type is specifically
        real(rk),  dimension(:,:), allocatable :: mat

    contains
        !> Initializers
        generic, public :: init => init_gen, init_square
        procedure, private :: init_gen      !> Initialize block with general-sized matrix storage
        procedure, private :: init_square   !> Initialize block with square-sized matrix storage

        !> Getters
        !! Block dimensions
        !!
        !!      ---> j
        !!  |
        !!  |
        !!  v
        !!
        !!  i
        procedure :: dparent    !> return parent domain
        procedure :: eparent    !> return parent element
        procedure :: nentries   !> return number of matrix entries
        procedure :: idim       !> return i-dimension of matrix storage
        procedure :: jdim       !> return j-dimension of matrix storage

        !> Setters
        procedure :: set_dparent !> assign domain parent
        procedure :: set_eparent !> assign element parent
        procedure :: resize     !> resize matrix storage
        procedure :: reparent   !> reassign parent

        procedure :: dump       !> print out matrix contents

        final :: destructor
    end type densematrix_t



    private
contains

    !> Subroutine for initializing general dense-block storage
    !-----------------------------------------------------------
    subroutine init_gen(self,idim,jdim,dparent,eparent)
        class(densematrix_t), intent(inout)  :: self
        integer(ik),         intent(in)     :: idim, jdim, dparent, eparent

        integer(ik) :: ierr
        integer :: test

        ! Block parents
        self%dparent_ = dparent
        self%eparent_ = eparent

        ! Allocate block storage
        ! Check if storage was already allocated and reallocate if necessary
        if (allocated(self%mat)) then
            deallocate(self%mat)
            allocate(self%mat(idim,jdim),stat=ierr)
        else
            allocate(self%mat(idim,jdim),stat=ierr)
        end if
        if (ierr /= 0) call AllocationError

        ! Initialize to zero
        self%mat = 0._rk
    end subroutine



    !> Subroutine for initializing square dense-block storage
    !-----------------------------------------------------------
    subroutine init_square(self,bsize,dparent,eparent)
        class(densematrix_t), intent(inout)  :: self
        integer(ik),         intent(in)     :: bsize, dparent, eparent

        integer(ik) :: ierr

        ! Block parents
        self%dparent_ = dparent
        self%eparent_ = eparent

        ! Allocate block storage
        ! Check if storage was already allocated and reallocate if necessary
        if (allocated(self%mat)) then
            deallocate(self%mat)
            allocate(self%mat(bsize,bsize),stat=ierr)
        else
            allocate(self%mat(bsize,bsize),stat=ierr)
        end if
        if (ierr /= 0) call AllocationError

        ! Initialize to zero
        self%mat = 0._rk
    end subroutine






    !> return i-dimension of block storage
    !------------------------------------------------------------
    function idim(self) result(i)
        class(densematrix_t), intent(in)   :: self
        integer(ik)                       :: i

        i = size(self%mat,1)
    end function

    !> return j-dimension of block storage
    !------------------------------------------------------------
    function jdim(self) result(j)
        class(densematrix_t), intent(in)   :: self
        integer(ik)                       :: j

        j = size(self%mat,2)
    end function

    !> return number of entries in block storage
    !------------------------------------------------------------
    function nentries(self) result(n)
        class(densematrix_t), intent(in)   :: self
        integer(ik)                  :: n

        n = size(self%mat,1) * size(self%mat,2)
    end function



    !> return index of parent domain
    !------------------------------------------------------------
    function dparent(self) result(par)
        class(densematrix_t),   intent(in)  :: self
        integer(ik)                         :: par

        par = self%dparent_
    end function



    !> return index of parent element
    !------------------------------------------------------------
    function eparent(self) result(par)
        class(densematrix_t), intent(in) :: self
        integer(ik)                     :: par

        par = self%eparent_
    end function



    !> Resize dense-block storage
    !------------------------------------------------------------
    subroutine resize(self,idim,jdim)
        class(densematrix_t), intent(inout)  :: self
        integer(ik),         intent(in)     :: idim,jdim

        integer(ik) :: ierr

        ! Allocate block storage
        ! Check if storage was already allocated and reallocate if necessary
        if (allocated(self%mat)) then
            deallocate(self%mat)
            allocate(self%mat(idim,jdim),stat=ierr)
        else
            allocate(self%mat(idim,jdim),stat=ierr)
        end if
        if (ierr /= 0) call AllocationError

    end subroutine


    !> set index of parent
    !
    !   **Deprecated**
    !
    !------------------------------------------------------------
    subroutine reparent(self,par)
        class(densematrix_t), intent(inout)  :: self
        integer(ik),         intent(in)     :: par

        self%eparent_ = par
    end subroutine





    !> set domain index of parent
    !------------------------------------------------------------
    subroutine set_dparent(self,par)
        class(densematrix_t), intent(inout)  :: self
        integer(ik),          intent(in)     :: par

        self%dparent_ = par
    end subroutine



    !> set element index of parent
    !------------------------------------------------------------
    subroutine set_eparent(self,par)
        class(densematrix_t), intent(inout)  :: self
        integer(ik),          intent(in)     :: par

        self%eparent_ = par
    end subroutine





    subroutine dump(self)
        class(densematrix_t), intent(inout) :: self


        integer(ik) :: irow

        print*, self%dparent_
        print*, self%eparent_

        do irow = 1,size(self%mat,1)
            print*, self%mat(irow,:)
        end do


    end subroutine












    subroutine destructor(self)
        type(densematrix_t), intent(inout) :: self

    end subroutine

end module type_densematrix
