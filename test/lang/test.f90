program
    foo




    type
        eigensys_t

        real(idp) :: bar1(:,:)



        integer    :: n
    end type eigensys_t

    do i = 1,
        eigensystem%n

        write(*,'(" Eigenvector ",I1,": ")') i


        write(*,*) eigensystem%eigen_vecs(:,i)
    end do

    contains
    subroutine aaaaaaaa(foo,
        bar)

        if (
            foo /= 0) then


            ! jask
        else if (
            foo /= 1) then


            foo = foo + 1
        else

            !das
            bar = 2
        endif
    end subroutine get_eigensystem

end program foo
