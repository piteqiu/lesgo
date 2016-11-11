!!
!!  Copyright (C) 2011-2013  Johns Hopkins University
!!
!!  This file is part of lesgo.
!!
!!  lesgo is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License as published by
!!  the Free Software Foundation, either version 3 of the License, or
!!  (at your option) any later version.
!!
!!  lesgo is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with lesgo.  If not, see <http://www.gnu.org/licenses/>.
!!

!*********************************************************************
module emul_complex
!*********************************************************************
! 
! The purpose of this module is to provide methods for performing
! complex operations against real arrays emulating complex arrays.  The
! real array is to contain interleaved complex information.
!  
! Written by : 
!     Jason Graham <jgraha8@gmail.com>
!

use types, only : rprec
use messages, only : error
implicit none

save
private 

! public :: mult_real_complex, &
!      mult_real_complex_imag, &
!      mult_real_complex_real 

public :: operator( .MUL. ), &
     operator( .MULI. ), &
     operator( .MULR. )
     
public :: conjugate, magnitude, multiply, real_part, imaginary_part

!///////////////////////////////////////
!/// OPERATORS                       ///
!///////////////////////////////////////

! REAL X COMPLEX
interface operator (.MUL.) 
   module procedure &
        mul_real_complex_2D
end interface

! REAL X IMAG(COMPLEX)
interface operator (.MULI.) 
   module procedure &
        mul_real_complex_imag_scalar, &
        mul_real_complex_imag_2D 
end interface

! REAL X REAL(COMPLEX)
interface operator (.MULR.)
   module procedure &
        mul_real_complex_real_2D
end interface

contains

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function mul_real_complex_imag_scalar( a, a_c ) result(b)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!
!  This function emulates the multiplication of two complex scalars
!  by emulating the input real vector (a) as a complex type. This 
!  subroutine ignores the real part of a_c (e.g. would use this when
!  real(a_c) = 0).
!
!  Input:
!  
!    a (real,size(2,1))  - input real vector
!    a_c (real)          - input imaginary part of complex scalar
!
!  Output:
!
!    b (real, size(2,1)) - output real vector
!
implicit none

real(rprec), dimension(2), intent(in) :: a
real(rprec), intent(in) :: a_c

real(rprec), dimension(2) :: b

!  Cached variables
real(rprec) :: a_c_i
  
!  Cache multi-usage variables
a_c_i = a_c

!  Perform multiplication
b(1) = - a(2) * a_c_i
b(2) =  a(1) * a_c_i

return

end function mul_real_complex_imag_scalar

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function mul_real_complex_2D( a, a_c ) result(b)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!  This function emulates the multiplication of two complex 2D array by
!  emulating the input real array (a) as a complex type.
!
!  Input:
!  
!    a (real,size(nx_r,ny))     - input real array
!    a_c (complex,size(nx_c,ny))- input complex array 
!
!  Output:
! 
!    b (real,size(nx_r,ny))     - output real array
!
!  Note: nx_c must be nx_r/2
!  
implicit none

real(rprec), dimension( :, :), intent(in) :: a
complex(rprec), dimension( :, : ), intent(in) :: a_c

real(rprec), allocatable, dimension(:, :) :: b

!  Cached variables
real(rprec) ::  a_r, a_i, a_c_r, a_c_i

integer :: i,j,ir,ii
integer :: nx_r, nx_c, ny

! Get the size of the incoming arrays
nx_r = size(a,1)
ny   = size(a,2)

nx_c = size(a_c,1)

! Allocate returned array
allocate( b(nx_r, ny) )

!  Emulate complex multiplication
!  Using outer loop to get contiguous memory access
do j=1, ny
  do i=1,nx_c

    !  Real and imaginary indicies of a
    ii = 2*i
    ir = ii-1
  
    !  Cache multi-usage variables
    a_r = a(ir,j)
    a_i = a(ii,j)
    a_c_r = real(a_c(i,j),kind=rprec)
    a_c_i = dimag(a_c(i,j))
    
    !  Perform multiplication
    b(ir,j) = a_r * a_c_r - a_i * a_c_i
    b(ii,j) = a_r * a_c_i + a_i * a_c_r

  enddo
enddo

return

end function mul_real_complex_2D


!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function mul_real_complex_imag_2D( a, a_c ) result(b)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!  This function emulates the multiplication of two complex 2D array by
!  emulating the input real array (a) as a complex type. This subroutine
!  ignores the real part of a_c (e.g. would use this when real(a_c) = 0)
!
!  Input:
!  
!    a (real,size(nx_r,ny))     - input real array
!    a_c (real,size(nx_c,ny))   - input imaginary part of complex array 
!
!  Output:
! 
!    b (real,size(nx_r,ny))     - output real array
!
!  Note: nx_c must be nx_r/2
!
implicit none

real(rprec), dimension( :, : ), intent(in) :: a
real(rprec), dimension( :, : ), intent(in) :: a_c

real(rprec), allocatable, dimension(:, :) :: b

!  Cached variables
real(rprec) ::  a_c_i, cache

integer :: i,j,ii,ir
integer :: nx_r, nx_c, ny

! Get the size of the incoming arrays
nx_r = size(a,1)
ny   = size(a,2)

nx_c = size(a_c,1)

! Allocate the returned array
allocate( b(nx_r, ny ) )

!  Emulate complex multiplication
do j=1, ny !  Using outer loop to get contiguous memory access
  do i=1,nx_c

    !  Real and imaginary indicies of a
    ii = 2*i
    ir = ii-1
  
    !  Cache multi-usage variables
    a_c_i = a_c(i,j)

    !  Perform multiplication (cache data to ensure sequential access)
    cache = a(ir,j) * a_c_i
    b(ir,j) = - a(ii,j) * a_c_i
    b(ii,j) =  cache

  enddo
enddo

return

end function mul_real_complex_imag_2D


!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function mul_real_complex_real_2D( a, a_c ) result(b)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!  This function emulates the multiplication of two complex 2D array by
!  emulating the input real array (a) as a complex type. This subroutine
!  ignores the imaginary part of a_c (e.g. would use this when imag(a_c)
!  = 0).
!
!  Input:
!  
!    a (real,size(nx_r,ny))     - input/output real array
!    a_c (real,size(nx_c,ny))   - input real part of complex array 
!
!  Output:
!
!    b (real, size(nx_r,ny))    - output real array
!
!  Note: nx_c must be nx_r/2
!
use types, only : rprec
implicit none

real(rprec), dimension( :, : ), intent(in) :: a
real(rprec), dimension( :, : ), intent(in) :: a_c

real(rprec), allocatable, dimension(:, :) :: b

integer :: i,j,ii,ir
integer :: nx_r, nx_c, ny

! Get the size of the incoming arrays
nx_r = size(a,1)
ny   = size(a,2)

nx_c = size(a_c,1)

allocate(b(nx_r,ny))

!  Emulate complex multiplication
do j=1, ny !  Using outer loop to get contiguous memory access
  do i=1,nx_c

    !  Real and imaginary indicies of a
    ii = 2*i
    ir = ii-1

    !  Perform multiplication
    b(ir:ii,j) = a_c(i,j)*a(ir:ii,j)

  enddo
enddo

return

end function mul_real_complex_real_2D

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function conjugate(c) result(cstar)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
real(rprec), dimension(:,:) :: c
real(rprec), dimension(:,:), allocatable :: cstar
integer :: nx, ny, i

if (mod(size(c,1),2) /= 0) then
    write(*,*) 'c is an invalid complex array'
end if

nx = size(c,1)/2
ny = size(c,2)

allocate( cstar(2*nx, ny) )

cstar = c
do i = 1, nx
    cstar(2*i,:) = -cstar(2*i,:)
end do

end function conjugate

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function magnitude(c) result(c_mag)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
real(rprec), dimension(:,:) :: c
real(rprec), dimension(:,:), allocatable :: c_mag
integer :: nx, ny, i, j

if (mod(size(c,1),2) /= 0) then
    write(*,*) 'c is an invalid complex array'
end if

nx = size(c,1)/2
ny = size(c,2)

allocate( c_mag(nx, ny) )

do i = 1, nx
    do j = 1, ny
        c_mag(i,j) = sqrt(c(2*i-1,j)**2 + c(2*i,j)**2)
    end do
end do

end function magnitude

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function multiply(c1, c2) result(c3)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
real(rprec), dimension(:, :) :: c1, c2
real(rprec), dimension(:, :), allocatable :: c3
integer :: nx, ny, i, j, ir, ic

if (size(c1,1) /= size(c2,1) .OR. size(c1,2) /= size(c2,2) ) then
    write(*,*) 'c1 and c2 must be the same size'
end if

if (mod(size(c1,1),2) /= 0) then
    write(*,*) 'c is an invalid complex array'
end if

nx = size(c1,1)/2
ny = size(c1,2)

allocate( c3(2*nx, ny) )

do i = 1, nx
    do j = 1, ny
        ir = 2*i-1
        ic = 2*i
        
        c3(ir,j) = c1(ir,j)*c2(ir,j) - c1(ic,j)*c2(ic,j)
        c3(ic,j) = c1(ir,j)*c2(ic,j) + c1(ic,j)*c2(ir,j)
    end do
end do

end function multiply

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function real_part(c) result(r)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
real(rprec), dimension(:, :) :: c
real(rprec), dimension(:, :), allocatable :: r
integer :: nx, ny
integer :: i, j

if (mod(size(c,1),2) /= 0) then
    write(*,*) 'c is an invalid complex array'
end if

nx = size(c,1)/2
ny = size(c,2)

allocate( r(nx, ny) )

do i = 1, nx
    do j = 1, ny
        r(i,j) = c(2*i-1,j)
    end do
end do

end function real_part

!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function imaginary_part(c) result(im)
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
real(rprec), dimension(:, :) :: c
real(rprec), dimension(:, :), allocatable :: im
integer :: nx, ny
integer :: i, j

if (mod(size(c,1),2) /= 0) then
    write(*,*) 'c is an invalid complex array'
end if

nx = size(c,1)/2
ny = size(c,2)

allocate( im(nx, ny) )

do i = 1, nx
    do j = 1, ny
        im(i,j) = c(2*i,j)
    end do
end do

end function imaginary_part


end module emul_complex
