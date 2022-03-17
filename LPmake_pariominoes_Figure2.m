function [p_shapes, r_shape, p_num, d, m, n, f] = LPmake_pariominoes_Figure2 ()

%*****************************************************************************80
%
%% LPmake_pariominoes_Figure2 () creates the LP file for Figure 2 in the reference below.
%
%  Discussion:
%
%    20 copies of the L-tetromino are used to tile the 9x9 single-notched square.
%
%    This problem is depicted in figure 2 in the reference given below.
%    Note that we tile with pariominoes, i.e. checkerboard colouring 
%    techniques are applied (cf.  LPmake_polyominoes_Figure2). 
%    
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license. 
%
%  Modified:
%
%    15 March 2022
%
%  Author:
%
%    Marcus Garvie, John Burkardt
%
%  Reference:
%
%    Marcus Garvie, John Burkardt,
%    A `divide-and-conquer' approach for tiling finite regions of the plane with polyominoes. 
%    Part II: Numerical solution.
%    Algorithms,
%    Submitted, 2022.
%
%  Output:
%
%    integer P_SHAPES(9,9,2): an array of 0's and +/- 1's that describes the pariominoes.
%
%    integer R_SHAPE(9,9): a matrix of 0's and +/- 1's that describes the checkerboard coloured region.
%
%    integer P_NUM, how many free pariominoes are used.
%
%    integer D(P_NUM), tells us how many copies of each pariomino
%    we must use in the tiling.
%
%    integer M: the number of constraints of the LP problem.
%
%    integer N: the number of variables in the LP problem.
%
%    integer F: the number of free variables associated with the linear
%    system Ax = b of the LP problem
%
%   Note: the LP file is saved to file.

%
%  Define the checkerboard coloured target region R
%
  r_shape = ones(9,9);
  r_shape(1,9) = 0;
  r_shape = colour_poly(r_shape, +1);
%
%  How many free pariominoes are there?
%
  p_num = 2;  
%
%  Create matrices of 0's and +/- 1's for the pariominoes and pack them into p_shapes
%  
  for page = 1 : p_num
    p_shapes(:,:,page) = zeros ( 9,9 );
  end
  
  poly1 = [1 0; 1 0; 1 1];
  poly1 = colour_poly(poly1, +1);
  p_shapes(1:3,1:2,1) = poly1;
  
  poly2 = [1 0; 1 0; 1 1];
  poly2 = colour_poly(poly2, -1);
  p_shapes(1:3,1:2,2) = poly2;

%
%  How many copies of each pariomino do we use?
%
  d = [4 16];
%
%  Create the linear system A*x=b for the tiling problem and output some data.
%
  [ a, b, ~ ] = pariomino_matrix ( r_shape, p_num, p_shapes, d );
  [m,n] = size(a); 
  f = n - rank([a,b]);
%
%  Write the linear system to an LP file.
%
  filename ='Figure2_pariominoes.lp';
  label = '\ LP file for Figure2 in the pariomino paper (colouring techniques used).';
  pariomino_lp_write ( filename, label, m, n, a, b );
  
  fprintf ( 1, '\n' );
  fprintf ( 1, '  LPmake_pariominoes_Figure2 created the LP file "%s"\n', filename );

  return 

end