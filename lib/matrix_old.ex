#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

# This file is the elixir-only version of the main matrix functions

# After much internal debate, the Matrix library always accepts and returns binary blobs
# that contain the matrix data. On many machine-specific implementations, these functions
# will actually go out to optimized hardware instructions that expect binary data in
# this form. So it is much easier if we start that way.

# Additionally, the scenic renderer will be much faster it it can stream the data to the GPU
# as is, instead of converting to binary every frame. In other words, if you want to manipulate
# the transforms yourself, use the Matrix.Utils functions, but store the data in binary format.
# in this way, we pay the transform to binary cost up front, instead of repeatedly at
# frame render time.

# The functions below all follow this basic pattern. Convert from binary, do some math, convert
# back to binary. Again, this is to gain some consistency on how you store the data. On most
# machines, you will use the hardware accelerated version, which will be binary only.

defmodule Scenic.Math.MatrixOld do
#  import IEx
  alias Scenic.Math.Vector
  alias Scenic.Math.MatrixOld, as: Matrix
  alias Scenic.Math.Matrix.Utils

  @binary_format        :binary
  @tuple_format         :tuple
  @default_format       @binary_format

  @matrix_zero      {
      {0.0, 0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0, 0.0}
    }
  @matrix_zero_bin  Utils.to_binary( @matrix_zero )

  @matrix_identity  {
      {1.0, 0.0, 0.0, 0.0},
      {0.0, 1.0, 0.0, 0.0},
      {0.0, 0.0, 1.0, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }
  @matrix_identity_bin  Utils.to_binary( @matrix_identity )


if Mix.env() == :dev do
  def time() do
    a = Matrix.build_rotation( 0.1 )
    b = Matrix.build_translation( 10, 20 )
    c = Matrix.build_rotation( -0.05 )
    Benchwarmer.benchmark fn -> Matrix.mul( [a,b,c,a,b,c] ) end
  end
end

  # common constants
  def zero( type \\ @default_format )
  def zero( @tuple_format ),            do: @matrix_zero
  def zero( @binary_format ),           do: @matrix_zero_bin

  def identity(type \\ @default_format )
  def identity( @tuple_format ),        do: @matrix_identity
  def identity( @binary_format ),       do: @matrix_identity_bin



  #============================================================================
  # explicit builders. Format dertmined by type indicator (last parameter)

  #--------------------------------------------------------
  # build a 2x2 matrix
  def build({v0x,v0y},{v1x,v1y}) do
    build({v0x,v0y},{v1x,v1y}, @default_format)
  end
  def build({v0x,v0y},{v1x,v1y}, @binary_format) do
    build({v0x,v0y},{v1x,v1y}, @tuple_format)
    |> Utils.to_binary()
  end
  def build({v0x,v0y},{v1x,v1y}, @tuple_format) do
    {
      {v0x, v0y, 0.0, 0.0},
      {v1x, v1y, 0.0, 0.0},
      {0.0, 0.0, 1.0, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }
  end

  #--------------------------------------------------------
  # build a 3x3 matrix
  def build({v0x,v0y,v0z},{v1x,v1y,v1z},{v2x,v2y,v2z}) do
    build({v0x,v0y,v0z},{v1x,v1y,v1z},{v2x,v2y,v2z}, @default_format)
  end
  def build({v0x,v0y,v0z},{v1x,v1y,v1z},{v2x,v2y,v2z}, @binary_format) do
    build({v0x,v0y,v0z},{v1x,v1y,v1z},{v2x,v2y,v2z}, @tuple_format)
    |> Utils.to_binary()
  end
  def build({v0x,v0y,v0z},{v1x,v1y,v1z},{v2x,v2y,v2z}, @tuple_format) do
    {
      {v0x, v0y, v0z, 0.0},
      {v1x, v1y, v1z, 0.0},
      {v2x, v2y, v2z, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }
  end

  #--------------------------------------------------------
  # build a 4x4 matrix
  def build({v0x,v0y,v0z,v0w},{v1x,v1y,v1z,v1w},{v2x,v2y,v2z,v2w},{v3x,v3y,v3z,v3w}) do
    build({v0x,v0y,v0z,v0w},{v1x,v1y,v1z,v1w},{v2x,v2y,v2z,v2w},{v3x,v3y,v3z,v3w}, @default_format)
  end
  def build({v0x,v0y,v0z,v0w},{v1x,v1y,v1z,v1w},{v2x,v2y,v2z,v2w},{v3x,v3y,v3z,v3w}, @binary_format) do
    build({v0x,v0y,v0z,v0w},{v1x,v1y,v1z,v1w},{v2x,v2y,v2z,v2w},{v3x,v3y,v3z,v3w}, @tuple_format)
    |> Utils.to_binary()
  end
  def build({v0x,v0y,v0z,v0w},{v1x,v1y,v1z,v1w},{v2x,v2y,v2z,v2w},{v3x,v3y,v3z,v3w}, @tuple_format) do
    {
      {v0x, v0y, v0z, v0w},
      {v1x, v1y, v1z, v1w},
      {v2x, v2y, v2z, v2w},
      {v3x, v3y, v3z, v3w}
    }
  end


  #============================================================================
  # specific builders. each does a certain job

  #--------------------------------------------------------
  # translation matrix

  def build_translation(tr) when is_tuple(tr),    do: build_translation(tr, @default_format)
  def build_translation({x, y}, type),            do: build_translation(x, y, 0.0, type)
  def build_translation({x, y, z}, type),         do: build_translation(x, y, z, type)
  def build_translation(x, y),                    do: build_translation(x, y, 0.0, @default_format)
  def build_translation(x, y, t) when is_atom(t), do: build_translation(x, y, 0.0, t)
  def build_translation(x, y, z),                 do: build_translation(x, y, z, @default_format)
  def build_translation(x, y, z, @binary_format) do
    build_translation(x, y, z, @tuple_format)
    |> Utils.to_binary()
  end
  def build_translation(x, y, z, @tuple_format) do
    {
      {1.0, 0.0, 0.0, x*1.0},
      {0.0, 1.0, 0.0, y*1.0},
      {0.0, 0.0, 1.0, z*1.0},
      {0.0, 0.0, 0.0, 1.0  }
    }
  end

  #--------------------------------------------------------
  # scale matrix

  def build_scale(s) when is_number(s),     do: build_scale(s, s, s, @default_format)
  def build_scale(s) when is_tuple(s),      do: build_scale(s, @default_format)
  def build_scale({x, y}, type),            do: build_scale(x, y, 1.0, type)
  def build_scale({x, y, z}, type),         do: build_scale(x, y, z, type)
  def build_scale(s, t) when is_atom(t),    do: build_scale(s, s, s, t)
  def build_scale(x, y),                    do: build_scale(x, y, 1.0, @default_format)
  def build_scale(x, y, t) when is_atom(t), do: build_scale(x, y, 1.0, t)
  def build_scale(x, y, z),                 do: build_scale(x, y, z, @default_format)
  
  def build_scale(x, y, z, @binary_format) do
    build_scale(x, y, z, @tuple_format)
    |> Utils.to_binary()
  end
  def build_scale(x, y, z, @tuple_format) do
    {
      {x*1.0, 0.0,   0.0,   0.0},
      {0.0,   y*1.0, 0.0,   0.0},
      {0.0,   0.0,   z*1.0, 0.0},
      {0.0,   0.0,   0.0,   1.0}
    }
  end


  #--------------------------------------------------------
  # rotation matrix

  def build_rotation( {radians, axis} )
      when is_number(radians) and is_atom(axis) do
    build_rotation( radians, axis )
  end

  def build_rotation( radians, axis \\ :z, type \\ @default_format )

  def build_rotation( radians, axis, @binary_format ) do
    build_rotation(radians, axis, @tuple_format)
    |> Utils.to_binary()
  end

  def build_rotation( radians, :x, @tuple_format ) do
    cos = :math.cos( radians )
    sin = :math.sin( radians )
    {
      {1.0, 0.0, 0.0, 0.0},
      {0.0, cos, sin, 0.0},
      {0.0, -sin, cos, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }
  end

  def build_rotation( radians, :y, @tuple_format ) do
    cos = :math.cos( radians )
    sin = :math.sin( radians )
    {
      {cos, 0.0, sin, 0.0},
      {0.0, 1.0, 0.0, 0.0},
      {-sin, 0.0, cos, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }
  end

  def build_rotation( radians, :z, @tuple_format ) do
    cos = :math.cos( radians )
    sin = :math.sin( radians )
    {
      {cos, sin, 0.0, 0.0},
      {-sin, cos, 0.0, 0.0},
      {0.0, 0.0, 1.0, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }
  end

  #--------------------------------------------------------
  def build_rotate_around( radians, point, axis \\ :z, type \\ @default_format)
  def build_rotate_around( radians, point, axis, type ) do
    Vector.invert( point )
    |> build_translation( type )
    |> Matrix.mul( build_rotation( radians, axis, type ) )
    |> Matrix.mul( build_translation( point, type ) )
  end


  #============================================================================
  # act on a matrix

  #--------------------------------------------------------
  def rotate( matrix, {radians, axis} ),  do: rotate( matrix, radians, axis )
  def rotate( matrix, nil ),              do: matrix
  def rotate( matrix, radians, axis ) when is_atom(axis) do
    build_rotation( radians, axis )
    |> ( &Matrix.mul(matrix, &1) ).()
  end

  #--------------------------------------------------------
  def translate( matrix, {x, y} ),    do: translate( matrix, x, y )
  def translate( matrix, {x, y, z} ), do: translate( matrix, x, y, z )
  def translate( matrix, nil ),       do: matrix
  def translate( matrix, x, y ),      do: build_translation( x, y )     |> (&Matrix.mul(matrix, &1)).()
  def translate( matrix, x, y, z ),   do: build_translation( x, y, z )  |> (&Matrix.mul(matrix, &1)).()

  #--------------------------------------------------------
  def scale( matrix, {x, y} ),        do: scale( matrix, x, y )
  def scale( matrix, {x, y, z} ),     do: scale( matrix, x, y, z )
  def scale( matrix, nil ),           do: matrix
  def scale( matrix, s ),             do: build_scale( s )              |> (&Matrix.mul(matrix, &1)).()
  def scale( matrix, x, y ),          do: build_scale( x, y )           |> (&Matrix.mul(matrix, &1)).()
  def scale( matrix, x, y, z ),       do: build_scale( x, y, z )        |> (&Matrix.mul(matrix, &1)).()



  #============================================================================
  # get / set values

  #--------------------------------------------------------
  def get(matrix, x, y)

  def get({{v,_,_,_},_,_,_}, 0, 0), do: v
  def get({{_,v,_,_},_,_,_}, 1, 0), do: v
  def get({{_,_,v,_},_,_,_}, 2, 0), do: v
  def get({{_,_,_,v},_,_,_}, 3, 0), do: v

  def get({_,{v,_,_,_},_,_}, 0, 1), do: v
  def get({_,{_,v,_,_},_,_}, 1, 1), do: v
  def get({_,{_,_,v,_},_,_}, 2, 1), do: v
  def get({_,{_,_,_,v},_,_}, 3, 1), do: v

  def get({_,_,{v,_,_,_},_}, 0, 2), do: v
  def get({_,_,{_,v,_,_},_}, 1, 2), do: v
  def get({_,_,{_,_,v,_},_}, 2, 2), do: v
  def get({_,_,{_,_,_,v},_}, 3, 2), do: v

  def get({_,_,_,{v,_,_,_}}, 0, 3), do: v
  def get({_,_,_,{_,v,_,_}}, 1, 3), do: v
  def get({_,_,_,{_,_,v,_}}, 2, 3), do: v
  def get({_,_,_,{_,_,_,v}}, 3, 3), do: v

  def get(m, x, y) when is_binary(m) do
    m
    |> Utils.to_tuple()
    |> get( x, y )
  end


  #--------------------------------------------------------
  def get_xy(matrix)
  def get_xy(m) do
    {
      get(m, 3, 0),
      get(m, 3, 1)
    }
  end

  #--------------------------------------------------------
  def get_xyz(matrix)
  def get_xyz(m) do
    {
      get(m, 3, 0),
      get(m, 3, 1),
      get(m, 3, 2)
    }
  end

  #--------------------------------------------------------
  def put(matrix, x, y, value)

  def put({{_,v1,v2,v3},r1,r2,r3}, 0, 0, v), do: {{v*1.0,v1,v2,v3},r1,r2,r3}
  def put({{v0,_,v2,v3},r1,r2,r3}, 1, 0, v), do: {{v0,v*1.0,v2,v3},r1,r2,r3}
  def put({{v0,v1,_,v3},r1,r2,r3}, 2, 0, v), do: {{v0,v1,v*1.0,v3},r1,r2,r3}
  def put({{v0,v1,v2,_},r1,r2,r3}, 3, 0, v), do: {{v0,v1,v2,v*1.0},r1,r2,r3}

  def put({r0,{_,v1,v2,v3},r2,r3}, 0, 1, v), do: {r0,{v*1.0,v1,v2,v3},r2,r3}
  def put({r0,{v0,_,v2,v3},r2,r3}, 1, 1, v), do: {r0,{v0,v*1.0,v2,v3},r2,r3}
  def put({r0,{v0,v1,_,v3},r2,r3}, 2, 1, v), do: {r0,{v0,v1,v*1.0,v3},r2,r3}
  def put({r0,{v0,v1,v2,_},r2,r3}, 3, 1, v), do: {r0,{v0,v1,v2,v*1.0},r2,r3}

  def put({r0,r1,{_,v1,v2,v3},r3}, 0, 2, v), do: {r0,r1,{v*1.0,v1,v2,v3},r3}
  def put({r0,r1,{v0,_,v2,v3},r3}, 1, 2, v), do: {r0,r1,{v0,v*1.0,v2,v3},r3}
  def put({r0,r1,{v0,v1,_,v3},r3}, 2, 2, v), do: {r0,r1,{v0,v1,v*1.0,v3},r3}
  def put({r0,r1,{v0,v1,v2,_},r3}, 3, 2, v), do: {r0,r1,{v0,v1,v2,v*1.0},r3}

  def put({r0,r1,r2,{_,v1,v2,v3}}, 0, 3, v), do: {r0,r1,r2,{v*1.0,v1,v2,v3}}
  def put({r0,r1,r2,{v0,_,v2,v3}}, 1, 3, v), do: {r0,r1,r2,{v0,v*1.0,v2,v3}}
  def put({r0,r1,r2,{v0,v1,_,v3}}, 2, 3, v), do: {r0,r1,r2,{v0,v1,v*1.0,v3}}
  def put({r0,r1,r2,{v0,v1,v2,_}}, 3, 3, v), do: {r0,r1,r2,{v0,v1,v2,v*1.0}}

  def put(m, x, y, v) when is_binary(m) do
    m
    |> Utils.to_tuple()
    |> put( x, y, v )
    |> Utils.to_binary()
  end

  #--------------------------------------------------------
  # test if two matrices are close. Is sometimes better than
  # testing equality as floating point errors can be a factor
  def close?(a,b, within  \\ 0.000001)
  def close?({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    },{
      {b00,b10,b20,b30},
      {b01,b11,b21,b31},
      {b02,b12,b22,b32},
      {b03,b13,b23,b33}
    }, within)  when is_number(within) do
    abs(a00 - b00) < within &&
    abs(a10 - b10) < within &&
    abs(a20 - b20) < within &&
    abs(a30 - b30) < within &&

    abs(a01 - b01) < within &&
    abs(a11 - b11) < within &&
    abs(a21 - b21) < within &&
    abs(a31 - b31) < within &&

    abs(a02 - b02) < within &&
    abs(a12 - b12) < within &&
    abs(a22 - b22) < within &&
    abs(a32 - b32) < within &&

    abs(a03 - b03) < within &&
    abs(a13 - b13) < within &&
    abs(a23 - b23) < within &&
    abs(a33 - b33) < within
  end
  def close?(a,b, within) when is_binary(a) and is_binary(b) do
    close?(
      Utils.to_tuple(a),
      Utils.to_tuple(b),
      within
    )
  end

  #--------------------------------------------------------
  # the transpose of a matrix
  def transpose({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    }) do
    {
      {a00,a01,a02,a03},
      {a10,a11,a12,a13},
      {a20,a21,a22,a23},
      {a30,a31,a32,a33}
    }
  end
  def transpose( a ) when is_binary(a) do
    a
    |> Utils.to_tuple()
    |> transpose()
    |> Utils.to_binary()
  end

  #============================================================================
  # from here down are functions that will often be replaced with system specific versions

  #--------------------------------------------------------
  # add two matrixes
  def add({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    },{
      {b00,b10,b20,b30},
      {b01,b11,b21,b31},
      {b02,b12,b22,b32},
      {b03,b13,b23,b33}
    }) do
    {
      {a00 + b00, a10 + b10, a20 + b20, a30 + b30},
      {a01 + b01, a11 + b11, a21 + b21, a31 + b31},
      {a02 + b02, a12 + b12, a22 + b22, a32 + b32},
      {a03 + b03, a13 + b13, a23 + b23, a33 + b33}
    }
  end
  def add(a,b) when is_binary(a) and is_binary(b) do
    Matrix.add(
      Utils.to_tuple(a),
      Utils.to_tuple(b)
    )
    |> Utils.to_binary()
  end

  #--------------------------------------------------------
  # subtract two matrixes
  def sub({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    },{
      {b00,b10,b20,b30},
      {b01,b11,b21,b31},
      {b02,b12,b22,b32},
      {b03,b13,b23,b33}
    }) do
    {
      {a00 - b00, a10 - b10, a20 - b20, a30 - b30},
      {a01 - b01, a11 - b11, a21 - b21, a31 - b31},
      {a02 - b02, a12 - b12, a22 - b22, a32 - b32},
      {a03 - b03, a13 - b13, a23 - b23, a33 - b33}
    }
  end
  def sub(a,b) when is_binary(a) and is_binary(b) do
    Matrix.sub(
      Utils.to_tuple(a),
      Utils.to_tuple(b)
    )
    |> Utils.to_binary()
  end

  #--------------------------------------------------------
  # multiply two matrixes
  def mul({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    },{
      {b00,b10,b20,b30},
      {b01,b11,b21,b31},
      {b02,b12,b22,b32},
      {b03,b13,b23,b33}
    }) do
    {
      {
        (a00 * b00) + (a10 * b01) + (a20 * b02) + (a30 * b03),
        (a00 * b10) + (a10 * b11) + (a20 * b12) + (a30 * b13),
        (a00 * b20) + (a10 * b21) + (a20 * b22) + (a30 * b23),
        (a00 * b30) + (a10 * b31) + (a20 * b32) + (a30 * b33)
      },
      {
        (a01 * b00) + (a11 * b01) + (a21 * b02) + (a31 * b03),
        (a01 * b10) + (a11 * b11) + (a21 * b12) + (a31 * b13),
        (a01 * b20) + (a11 * b21) + (a21 * b22) + (a31 * b23),
        (a01 * b30) + (a11 * b31) + (a21 * b32) + (a31 * b33)
      },
      {
        (a02 * b00) + (a12 * b01) + (a22 * b02) + (a32 * b03),
        (a02 * b10) + (a12 * b11) + (a22 * b12) + (a32 * b13),
        (a02 * b20) + (a12 * b21) + (a22 * b22) + (a32 * b23),
        (a02 * b30) + (a12 * b31) + (a22 * b32) + (a32 * b33)
      },
      {
        (a03 * b00) + (a13 * b01) + (a23 * b02) + (a33 * b03),
        (a03 * b10) + (a13 * b11) + (a23 * b12) + (a33 * b13),
        (a03 * b20) + (a13 * b21) + (a23 * b22) + (a33 * b23),
        (a03 * b30) + (a13 * b31) + (a23 * b32) + (a33 * b33)
      }
    }
  end

  def mul(a,b) when is_binary(a) and is_binary(b) do
    Matrix.mul(
      Utils.to_tuple(a),
      Utils.to_tuple(b)
    )
    |> Utils.to_binary()
  end

  #--------------------------------------------------------
  # multiply by a scalar
  def mul({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    }, s) when is_number(s) do
    {
      {a00 * s, a10 * s, a20 * s, a30 * s},
      {a01 * s, a11 * s, a21 * s, a31 * s},
      {a02 * s, a12 * s, a22 * s, a32 * s},
      {a03 * s, a13 * s, a23 * s, a33 * s}
    }
  end

  # multiply by a scalar
  def mul(a, s) when is_binary(a) and is_number(s) do
    a
    |> Utils.to_tuple()
    |> Matrix.mul( s )
    |> Utils.to_binary()
  end

  #--------------------------------------------------------
  # multiply down a list
  def mul(matrix_list) when is_list(matrix_list) do
    do_mul_list( @matrix_identity, matrix_list )
  end

  defp do_mul_list( m, [] ), do: m
  defp do_mul_list( m, [head | tail] ) do
    Matrix.mul(m, head)
    |>  do_mul_list( tail )
  end

  #--------------------------------------------------------
  # divide by a scalar
  def div({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    }, s) when is_number(s) do
    {
      {a00 / s, a10 / s, a20 / s, a30 / s},
      {a01 / s, a11 / s, a21 / s, a31 / s},
      {a02 / s, a12 / s, a22 / s, a32 / s},
      {a03 / s, a13 / s, a23 / s, a33 / s}
    }
  end
  def div(a, s) when is_binary(a) and is_number(s) do
    a
    |> Utils.to_tuple()
    |> Matrix.div( s * 1.0 )
    |> Utils.to_binary()
  end


  #--------------------------------------------------------
  # invert the matrix
  # the inverted matrix times the matrix is the identity matrix

  def invert(a) when is_tuple(a) do
    case determinant(a) do
      0.0 -> :err_zero_determinant
      det ->
        a
        |> adjugate()
        |> Matrix.mul( 1.0 / det )
    end
  end
  def invert(a) when is_binary(a) do
    a
    |> Utils.to_tuple()
    |> invert()
    |> Utils.to_binary()
  end


  #--------------------------------------------------------
  # see http://ncalculators.com/matrix/4x4-inverse-matrix-calculator.htm
  # the adjunct matrix
  def adjugate({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    }) do
      {
        {
          (a11*a22*a33) + (a12*a23*a31) + (a13*a21*a32) - (a11*a23*a32) - (a12*a21*a33) - (a13*a22*a31),
          (a01*a23*a32) + (a02*a21*a33) + (a03*a22*a31) - (a01*a22*a33) - (a02*a23*a31) - (a03*a21*a32),
          (a01*a12*a33) + (a02*a13*a31) + (a03*a11*a32) - (a01*a13*a32) - (a02*a11*a33) - (a03*a12*a31),
          (a01*a13*a22) + (a02*a11*a23) + (a03*a12*a21) - (a01*a12*a23) - (a02*a13*a21) - (a03*a11*a22) 
        },
        {
          (a10*a23*a32) + (a12*a20*a33) + (a13*a22*a30) - (a10*a22*a33) - (a12*a23*a30) - (a13*a20*a32),
          (a00*a22*a33) + (a02*a23*a30) + (a03*a20*a32) - (a00*a23*a32) - (a02*a20*a33) - (a03*a22*a30),
          (a00*a13*a32) + (a02*a10*a33) + (a03*a12*a30) - (a00*a12*a33) - (a02*a13*a30) - (a03*a10*a32),
          (a00*a12*a23) + (a02*a13*a20) + (a03*a10*a22) - (a00*a13*a22) - (a02*a10*a23) - (a03*a12*a20)
        },
        {
          (a10*a21*a33) + (a11*a23*a30) + (a13*a20*a31) - (a10*a23*a31) - (a11*a20*a33) - (a13*a21*a30),
          (a00*a23*a31) + (a01*a20*a33) + (a03*a21*a30) - (a00*a21*a33) - (a01*a23*a30) - (a03*a20*a31),
          (a00*a11*a33) + (a01*a13*a30) + (a03*a10*a31) - (a00*a13*a31) - (a01*a10*a33) - (a03*a11*a30),
          (a00*a13*a21) + (a01*a10*a23) + (a03*a11*a20) - (a00*a11*a23) - (a01*a13*a20) - (a03*a10*a21)
        },
        {
          (a10*a22*a31) + (a11*a20*a32) + (a12*a21*a30) - (a10*a21*a32) - (a11*a22*a30) - (a12*a20*a31),
          (a00*a21*a32) + (a01*a22*a30) + (a02*a20*a31) - (a00*a22*a31) - (a01*a20*a32) - (a02*a21*a30),
          (a00*a12*a31) + (a01*a10*a32) + (a02*a11*a30) - (a00*a11*a32) - (a01*a12*a30) - (a02*a10*a31),
          (a00*a11*a22) + (a01*a12*a20) + (a02*a10*a21) - (a00*a12*a21) - (a01*a10*a22) - (a02*a11*a20)
        }
      }
      |> transpose()
  end
  def adjugate(a) when is_atom(a), do: a
  def adjugate(a) when is_binary(a) do
    a
    |> Utils.to_tuple()
    |> adjugate()
    |> Utils.to_binary()
  end

  #--------------------------------------------------------
  # the determinant of a matrix
  def determinant({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    }) do
  (a00*a11*a22*a33) + (a00*a12*a23*a31) + (a00*a13*a21*a32) +
  (a01*a10*a23*a32) + (a01*a12*a20*a33) + (a01*a13*a22*a30) +
  (a02*a10*a21*a33) + (a02*a11*a23*a30) + (a02*a13*a20*a31) +
  (a03*a10*a22*a31) + (a03*a11*a20*a32) + (a03*a12*a21*a30) -
  (a00*a11*a23*a32) - (a00*a12*a21*a33) - (a00*a13*a22*a31) -
  (a01*a10*a22*a33) - (a01*a12*a23*a30) - (a01*a13*a20*a32) - 
  (a02*a10*a23*a31) - (a02*a11*a20*a33) - (a02*a13*a21*a30) - 
  (a03*a10*a21*a32) - (a03*a11*a22*a30) - (a03*a12*a20*a31)
  end
  def determinant( a ) when is_binary(a) do
    a
    |> Utils.to_tuple()
    |> determinant()
  end

end















