! {{TEST}}
program ! {{CONTEXT}}
    foo



    ! {{CURSOR}}
    type ! {{CONTEXT}}
        eigensys_t

        real(idp) :: bar1(:,:)



        integer    :: n ! {{CURSOR}}
    end type eigensys_t ! {{POPCONTEXT}}

    do i = 1, ! {{CONTEXT}}
        eigensystem%n

        write(*,'(" Eigenvector ",I1,": ")') i


        write(*,*) eigensystem%eigen_vecs(:,i) ! {{CURSOR}}
    end do ! {{POPCONTEXT}}

    contains
    subroutine aaaaaaaa(foo, ! {{CONTEXT}}
        bar)

        if ( ! {{CONTEXT}}
            foo /= 0) then


            ! {{CURSOR}}
        else if (
            foo /= 1) then


            foo = foo + 1
        else ! {{CONTEXT}}

            ! BUG: cannot mark cursor here
            bar = 2
        endif
    end subroutine get_eigensystem

end program foo
