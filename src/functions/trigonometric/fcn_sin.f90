module fcn_sin
#include <messenger.h>
    use mod_kinds,      only: rk,ik
    use mod_constants,  only: ZERO, ONE, TWO, THREE, FIVE, PI
    use type_point,     only: point_t
    use type_function,  only: function_t
    implicit none





    !>  Gaussian function.
    !!
    !!  Three 1D Gaussian functions are computed; one for each dimension. They are multiplied
    !!  together to create a 3D version of the function.
    !!
    !!  \f$  f_x(t,\vec{x}) = a e^{- \frac{(x-b_x)^2}{2c^2} }    \\
    !!       f_y(t,\vec{x}) = a e^{- \frac{(y-b_y)^2}{2c^2} }    \\
    !!       f_z(t,\vec{x}) = a e^{- \frac{(z-b_z)^2}{2c^2} }    \\
    !!       f(t,\vec{x}) = f_x * f_y * f_z                      \f$
    !!
    !!  Function parameters:
    !!
    !!  \f$ a   -   \text{Amplitude of the distribution}   \\
    !!      b_i -   \text{Offset in coordinate 'i'}        \\
    !!      c   -   \text{Width of the distribution}   \f$
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/1/2016
    !!
    !-------------------------------------------------------------------------------------
    type, extends(function_t), public :: sin_f


    contains

        procedure   :: init
        procedure   :: compute

    end type sin_f
    !*************************************************************************************



contains



    !>
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/2/2016
    !!
    !-------------------------------------------------------------------------
    subroutine init(self)
        class(sin_f),  intent(inout)   :: self

        !
        ! Set function name
        !
        call self%add_name("A_p_Bsin(y)")


        !
        ! Set function options to default settings
        !
        call self%add_option('mean', 1._rk)
        call self%add_option('amplitude', 1._rk)
        call self%add_option('period', 2._rk * PI)



    end subroutine init
    !*************************************************************************







    !>
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/2/2016
    !!
    !----------------------------------------------------------------------------------
    impure elemental function compute(self,time,coord) result(val)
        class(sin_f),  intent(inout)  :: self
        real(rk),           intent(in)  :: time
        type(point_t),      intent(in)  :: coord

        real(rk)                        :: val

        real(rk)    :: x,   y,   z, &
                       mean, amp, period

        !
        ! Get inputs and function parameters
        !
        x = coord%c1_
        y = coord%c2_
        z = coord%c3_

        mean   = self%get_option_value('mean')
        amp    = self%get_option_value('amplitude')
        period = self%get_option_value('period')


        !
        ! Compute function
        !
        val = mean + amp * sin(period * y)

    end function compute
    !***********************************************************************************


end module fcn_sin
