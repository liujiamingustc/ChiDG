!>
!!
!!  @author Nathan A. Wukie
!!  @date   2/3/2016
!!
!!
!!
!!
!----------------------------------------------------------------------------------------
module mod_chidg_edit
#include <messenger.h>
    use mod_kinds,  only: rk, ik
    use hdf5
    use h5lt

    use mod_chidg_edit_boundaryconditions,  only: chidg_edit_boundaryconditions
    use mod_chidg_edit_matrixsolver,        only: chidg_edit_matrixsolver
    use mod_chidg_edit_timescheme,          only: chidg_edit_timescheme
    implicit none

















contains



    !>  ChiDG action: edit utility
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/3/2016
    !!
    !!  @parma[in]  file    Character string specifying an .h5 file in ChiDG format for editing.
    !!
    !--------------------------------------------------------------------------------------------
    subroutine chidg_edit(filename)
        character(*),   intent(in)  :: filename


        logical     :: run, fileexists
        integer(ik) :: ierr

        character(len=:),   allocatable :: char_input
        integer(ik)                     :: int_input
        real(rk)                        :: real_input

        character(len=:),   allocatable :: command_options

        integer(HID_T)     :: fid



        !call check_extension(file,'.h5')

        !
        ! Clear screen for editing
        ! TODO: portability check
        !
        call execute_command_line("clear")


        !
        ! Check that file can be found
        !
        inquire(file=filename, exist=fileexists)
        if ( .not. fileexists ) then
            call chidg_signal_one(FATAL,"chidg_edit: file not found for editing.",filename)
        end if


        !
        ! Initialize Fortran interface
        !
        call h5open_f(ierr)
        if (ierr /= 0) call chidg_signal(FATAL,"chidg_edit: HDF5 Fortran interface had an error during initialization.")


        !
        ! Get HDF file identifier
        !
        call h5fopen_f(filename, H5F_ACC_RDWR_F, fid, ierr)
        if (ierr /= 0) call chidg_signal_one(FATAL,"chidg_edit: Error opening HDF5 file for editing.",filename)








        command_options = "1 - boundary conditions, 2 - time scheme, 3 - matrix solver, 0 - exit"

        !
        ! Edit loop
        !
        run = .true.
        do while ( run )


            call print_overview(fid)



            print*, command_options
            ierr = 1
            do while ( ierr /= 0 )
                read(*,'(I3)', iostat=ierr) int_input
                if ( (ierr/=0) .or. (abs(int_input)>3) ) print*, "Invalid input: expecting 0, 1, 2, or 3."
            end do

            select case (int_input)
                case (0)
                    exit
                case (1)
                    call chidg_edit_boundaryconditions(fid)
                case (2)
                    call chidg_edit_timescheme(fid)
                case (3)
                    call chidg_edit_matrixsolver(fid)
                case default

            end select


        end do







        !
        ! Close HDF5 file and Fortran interface
        !
        call h5fclose_f(fid, ierr)  ! Close HDF5 File
        call h5close_f(ierr)        ! Close HDF5 Fortran interface








    end subroutine chidg_edit
    !********************************************************************************************






    




    !>
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/3/2016
    !!
    !!
    !!
    !!
    !----------------------------------------------------------------------------------------------
    subroutine print_overview(fid)
        integer(HID_T),    intent(in)  :: fid


    end subroutine print_overview
    !**********************************************************************************************

    









































end module mod_chidg_edit