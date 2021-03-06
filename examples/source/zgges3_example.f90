    Module zgges3_example_mod

!     ZGGES3 Example Program Module:

!     .. Implicit None Statement ..
      Implicit None
!     .. Accessibility Statements ..
      Private
      Public :: selctg
    Contains
      Function selctg(a, b)
!       .. Use Statements ..
        Use lapack_precision, Only: dp
!       .. Implicit None Statement ..
        Implicit None
!       .. Function Return Value ..
        Logical :: selctg
!       .. Scalar Arguments ..
        Complex (Kind=dp), Intent (In) :: a, b
!       .. Intrinsic Procedures ..
        Intrinsic :: abs
!       .. Executable Statements ..
        Continue

!       Dummy function - it is not called by ZGGES3 when sorting is not required.
        selctg = (abs(a)<6.0_dp*abs(b))

        Return
      End Function
    End Module
    Program zgges3_example

!     ZGGES3 Example Program Text

!     Copyright (c) 2018, Numerical Algorithms Group (NAG Ltd.)
!     For licence see
!       https://github.com/numericalalgorithmsgroup/LAPACK_Examples/blob/master/LICENCE.md

!     .. Use Statements ..
      Use blas_interfaces, Only: zgemm
      Use lapack_example_aux, Only: nagf_sort_cmplxvec_rank_rearrange, &
        nagf_sort_realvec_rank, nagf_file_print_matrix_complex_gen, &
        nagf_file_print_matrix_complex_gen_comp
      Use lapack_interfaces, Only: zgges3, zlange
      Use lapack_precision, Only: dp
      Use zgges3_example_mod, Only: selctg
!     .. Implicit None Statement ..
      Implicit None
!     .. Parameters ..
      Integer, Parameter :: nb = 64, nin = 5, nout = 6
!     .. Local Scalars ..
      Complex (Kind=dp) :: alph, bet
      Real (Kind=dp) :: normd, norme
      Integer :: i, ifail, info, lda, ldb, ldc, ldd, lde, ldvsl, ldvsr, lwork, &
        n, sdim
!     .. Local Arrays ..
      Complex (Kind=dp), Allocatable :: a(:, :), alpha(:), b(:, :), beta(:), &
        c(:, :), d(:, :), e(:, :), vsl(:, :), vsr(:, :), work(:)
      Complex (Kind=dp) :: wdum(1)
      Real (Kind=dp), Allocatable :: rwork(:)
      Integer, Allocatable :: irank(:)
      Logical, Allocatable :: bwork(:)
      Character (1) :: clabs(1), rlabs(1)
!     .. Intrinsic Procedures ..
      Intrinsic :: abs, all, cmplx, epsilon, max, nint, real
!     .. Executable Statements ..
      Write (nout, *) 'ZGGES3 Example Program Results'
      Write (nout, *)
      Flush (nout)
!     Skip heading in data file
      Read (nin, *)
      Read (nin, *) n
      lda = n
      ldb = n
      ldc = n
      ldd = n
      lde = n
      ldvsl = n
      ldvsr = n
      Allocate (a(lda,n), alpha(n), b(ldb,n), beta(n), c(ldc,n), d(ldd,n), &
        e(lde,n), vsl(ldvsl,n), vsr(ldvsr,n), rwork(8*n), bwork(n))

!     Use routine workspace query to get optimal workspace.
      lwork = -1
      Call zgges3('Vectors (left)', 'Vectors (right)', 'No sort', selctg, n, &
        a, lda, b, ldb, sdim, alpha, beta, vsl, ldvsl, vsr, ldvsr, wdum, &
        lwork, rwork, bwork, info)

!     Make sure that there is enough workspace for block size nb.
      lwork = max((nb+1)*n, nint(real(wdum(1))))
      Allocate (work(lwork))

!     Read in the matrices A and B
      Read (nin, *)(a(i,1:n), i=1, n)
      Read (nin, *)(b(i,1:n), i=1, n)

!     Copy A and B into D and E respectively
      d(1:n, 1:n) = a(1:n, 1:n)
      e(1:n, 1:n) = b(1:n, 1:n)

!     Print matrices A and B
!     ifail: behaviour on error exit
!            =0 for hard exit, =1 for quiet-soft, =-1 for noisy-soft
      ifail = 0
      Call nagf_file_print_matrix_complex_gen_comp('General', ' ', n, n, a, &
        lda, 'Bracketed', 'F8.4', 'Matrix A', 'Integer', rlabs, 'Integer', &
        clabs, 80, 0, ifail)
      Write (nout, *)
      Flush (nout)

      ifail = 0
      Call nagf_file_print_matrix_complex_gen_comp('General', ' ', n, n, b, &
        ldb, 'Bracketed', 'F8.4', 'Matrix B', 'Integer', rlabs, 'Integer', &
        clabs, 80, 0, ifail)
      Write (nout, *)
      Flush (nout)

!     Find the generalized Schur form
      Call zgges3('Vectors (left)', 'Vectors (right)', 'No sort', selctg, n, &
        a, lda, b, ldb, sdim, alpha, beta, vsl, ldvsl, vsr, ldvsr, work, &
        lwork, rwork, bwork, info)

      If (info>0) Then
        Write (nout, 100) 'Failure in ZGGES3. INFO =', info
      Else

!       Compute A - Q*S*Z^H from the factorization of (A,B) and store in
!       matrix D
        alph = cmplx(1, kind=dp)
        bet = cmplx(0, kind=dp)
        Call zgemm('N', 'N', n, n, n, alph, vsl, ldvsl, a, lda, bet, c, ldc)
        alph = cmplx(-1, kind=dp)
        bet = cmplx(1, kind=dp)
        Call zgemm('N', 'C', n, n, n, alph, c, ldc, vsr, ldvsr, bet, d, ldd)

!       Compute B - Q*T*Z^H from the factorization of (A,B) and store in
!       matrix E
        alph = cmplx(1, kind=dp)
        bet = cmplx(0, kind=dp)
        Call zgemm('N', 'N', n, n, n, alph, vsl, ldvsl, b, ldb, bet, c, ldc)
        alph = cmplx(-1, kind=dp)
        bet = cmplx(1, kind=dp)
        Call zgemm('N', 'C', n, n, n, alph, c, ldc, vsr, ldvsr, bet, e, lde)

!       Find norms of matrices D and E and warn if either is too large
        normd = zlange('O', ldd, n, d, ldd, rwork)
        norme = zlange('O', lde, n, e, lde, rwork)
        If (normd>epsilon(1.0E0_dp)**0.75_dp .Or. norme>epsilon(1.0E0_dp)** &
          0.75_dp) Then
          Write (nout, *) 'Norm of A-(Q*S*Z^H) or norm of B-(Q*T*Z^H) &
            &is much greater than 0.'
          Write (nout, *) 'Schur factorization has failed.'
        Else
!         Print generalized eigenvalues
          Write (nout, *) 'Generalized Eigenvalues'

          If (all(abs(beta(1:n))>epsilon(1.0E0_dp))) Then
            alpha(1:n) = alpha(1:n)/beta(1:n)
!           Reorder eigenvalues by descending absolute value
            rwork(1:n) = abs(alpha(1:n))
            Allocate (irank(n))
            ifail = 0
            Call nagf_sort_realvec_rank(rwork, 1, n, 'Descending', irank, &
              ifail)
            Call nagf_sort_cmplxvec_rank_rearrange(alpha, 1, n, irank, ifail)
            ifail = 0
            Call nagf_file_print_matrix_complex_gen('Gen', ' ', 1, n, alpha, &
              1, 'Eigenvalues:', ifail)
            Write (nout, *)
            Flush (nout)
          Else
            Do i = 1, n
              If (beta(i)/=0.0_dp) Then
                Write (nout, 110) i, alpha(i)/beta(i)
              Else
                Write (nout, 120) i
              End If
            End Do
          End If
        End If
      End If

100   Format (1X, A, I4)
110   Format (1X, I2, 1X, '(', 1P, E11.4, ',', E11.4, ')')
120   Format (1X, I4, 'Eigenvalue is infinite')
    End Program
