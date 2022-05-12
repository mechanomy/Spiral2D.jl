# MIT License
# Copyright (c) 2022 Mechanomy LLC
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




module Spiral2D
using Unitful
using KeywordDispatch


export Spiral, calcPitch, calcLength, isIncreasing, isDecreasing, isClockwise, isCounterClockwise, seriesPolar, seriesCartesian


@derived_dimension Radian dimension(u"rad")
@derived_dimension Degree dimension(u"°")
# @unit rev "rev" Revolution (2*π)Radian false #why doesn't a variant of this work?
@unit rev "rev" Revolution (2*π)u"rad" false
Unitful.register(Spiral2D) # besides rev, does any of the following need to be registered?

Angle{T} = Union{Quantity{T,NoDims,Radian}, Quantity{T,NoDims,Degree}} where T 

@derived_dimension Pitch dimension(u"m/rev")

LengthOrNumber = Union{Unitful.Length, Number} #to accept Unitful.Length or plain Number
AngleOrNumber = Union{Angle, Number} #to accept Angle or Number
PitchOrNumber = Union{Pitch, Number}


"""Describes a spiral progressing from `a0`,`r0` to `a1`,`r1`. 
If `thickness` is not specified it is calculated such that each layer touches neighbors, a tightly wound spiral, if it is specified then an open spiral is modeled.
"""
struct Spiral
  a0::AngleOrNumber #start angle
  a1::AngleOrNumber #stop angle
  r0::LengthOrNumber #starting radius
  r1::LengthOrNumber #stopping radius
  pitch::PitchOrNumber #distance between consecutive layers. this is a field to be able to model tight and loose spirals
end
@kwdispatch Spiral()
# Spiral( a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber, pitch::LengthOrNumber) = Spiral( a0, a1, r0, r1, pitch )
Spiral( a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber ) = Spiral( a0, a1, r0, r1, calcPitch(a0,a1,r0,r1))
@kwmethod Spiral(; a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber, pitch::PitchOrNumber) = Spiral(a0, a1, r0, r1, pitch)
@kwmethod Spiral(; a0::Angle, a1::Angle, r0::Unitful.Length, r1::Unitful.Length) = Spiral(a0, a1, r0, r1, calcPitch(a0,a1,r0,r1)::Pitch )
@kwmethod Spiral(; a0::Number, a1::Number, r0::Number, r1::Number) = Spiral(a0, a1, r0, r1, calcPitch(a0,a1,r0,r1)::Number )


"""2D Spirals can be viewed as clockwise or counter-clockwise, depending on `a0`,`a1`"""
function isCounterClockwise(s::Spiral)
  return s.a0 < s.a1
end
"""2D Spirals can be viewed as clockwise or counter-clockwise, depending on `a0`,`a1`"""
function isClockwise(s::Spiral)
  return s.a0 > s.a1
end

"""Does the radius increase"""
function isIncreasing(s::Spiral)
  return s.r0 < s.r1
end
"""Does the radius decrease"""
function isDecreasing(s::Spiral)
  return s.r0 > s.r1
end

"""Calculate a spiral's pitch from (`r1`-`r0`)/(`a1`-`a0`).
The nominal units of Pitch defined to be [m/rev], but this will return Number if its args or Spiral are that, or a Pitch,m/rad,m/deg depending on __. 
Suggest uconvert()ing into a desired type.
"""
function calcPitch(a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber)
  return abs( (r1-r0)/(a1-a0) ) * ( r0<r1 ? 1 : -1)
end
calcPitch(; a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber) = calcPitch(a0,a1,r0,r1)
calcPitch(s::Spiral) = calcPitch(s.a0, s.a1, s.r0, s.r1)


"""Length along the spiral, as if it were unrolled.
"""
function calcLength(a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber)
  if r0 < 0*unit(r0)
    @warn "Spiral2D.calcLength() given r0=$r0, coerced to 0 as r0 < 0 is nonsensical."
    r0 = 0*unit(r0)
  end
  if r1 < 0*unit(r1)
    @warn "Spiral2D.calcLength() given r1=$r1, coerced to 0 as r1 < 0 is nonsensical."
    r1 = 0*unit(r1)

  end

  if a0 == a1 && r0 != r1 # a straight, radial line
    return r1-r0
  end

  # this is likely approximate, see https://www.engineeringtoolbox.com/spiral-length-d_2191.html 
  if 0*unit(r1) < r1
    return  ustrip(u"rad", (a1-a0)/2) * (r1+r0) 
  else 
    return 0*unit(r0)
  end
end
calcLength(;a0::AngleOrNumber, a1::AngleOrNumber, r0::LengthOrNumber, r1::LengthOrNumber) = calcLength(a0,a1,r0,r1)
calcLength(s::Spiral) = calcLength(s.a0, s.a1, s.r0, s.r1)


"""Spread `n` points over spiral `s`, returning an (`angles`,`radii`) tuple"""
function seriesPolar(s::Spiral, n::Int=1000)
  als = LinRange(s.a0, s.a1, n)
  rs = LinRange(s.r0, s.r1, n)
  return (collect(als),collect(rs))
end
seriesPolar(; s::Spiral, n::Int=1000) = seriesPolar(s, n)

"""Spread `n` points over spiral `s`, returning an (`xs`,`ys`) tuple"""
function seriesCartesian(s::Spiral, n::Int=1000)
  (als,rs) = seriesPolar(s, n)
  return ( rs .* cos.(als), rs .* sin.(als) )
end
seriesCartesian(; s::Spiral, n::Int=1000) = seriesCartesian(s,n)



end #Spiral2D
