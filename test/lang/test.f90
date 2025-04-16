! {{TEST}}
program ! {{CONTEXT}}
    foo ! {{CONTEXT}}



    ! {{CURSOR}}
    type ! {{CONTEXT}}
        eigensys_t ! {{CONTEXT}}

        real(idp) :: bar1(:,:)



        integer    :: n ! {{CURSOR}}
    end type eigensys_t ! {{POPCONTEXT}}
    ! {{POPCONTEXT}}

    do i = 1, ! {{CONTEXT}}
        eigensystem%n ! {{CONTEXT}}

        write(*,'(" Eigenvector ",I1,": ")') i


        write(*,*) eigensystem%eigen_vecs(:,i) ! {{CURSOR}}
    end do ! {{POPCONTEXT}}

    contains
    subroutine aaaaaaaa(foo,
        bar)

        if (
            foo /= 0) then



        else if (
            foo /= 1) then


            foo = foo + 1
        else

            ! BUG: cannot mark cursor here
            bar = 2
        endif
    end subroutine get_eigensystem

end program foo
