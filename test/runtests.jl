# MIT License
# Copyright (c) 2022 Mechanomy LLC
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


using Pkg
Pkg.activate( normpath(joinpath(@__DIR__, "..")) ) #activate this package
using Test
using Spiral2D
using Unitful

@testset "Spiral2D.jl number constructors" begin
    s1 = Spiral(1.1, 2.2, 3.3, 4.4, 0.1)
    @test s1.a0 == 1.1

    s3 = Spiral(1.1, 2.2, 3.3, 4.4)
    @test abs(s3.pitch - 1)<1e-4
end

@testset "Spiral2D.jl unitful constructors" begin
    s1 = Spiral(180u"°", 2.2u"°",3.3u"m",4.4u"m",5.5u"mm/rad")
    s2 = Spiral( π*u"rad", 2.2u"°",3.3u"m",4.4u"m",5.5u"mm/rad")
    @test s1.a0 == s2.a0

    s3 = Spiral(180u"°", 2.2u"°",3.3u"m",4.4u"m")
    # @show uconvert(u"m/rad", s3.pitch)
    @test abs(s3.pitch - 0.35447u"m/rad")<1e-4u"m/rad" #-0.35 is less than elegant, but rev is only defined in Spiral2D...not fixing unitful here
end

@testset "Spiral2D.jl mixed type constructor" begin
    s = Spiral(1.1, 2.2u"°", 3.3, 4.4u"m", 5.5u"mm/rad")
    @test s.a0 == 1.1u"rad"
    @test s.a1 == deg2rad(2.2)
end

@testset "Spiral2D.jl keyword constructor" begin
    s1 = Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m", pitch=5.5u"mm/rad")
    @test s1.a0 == 1.1u"°"

    s2 = Spiral(a0=π*u"rad", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m", pitch=5.5u"mm/rad")
    @test s2.a1 == deg2rad(2.2)

    s3 = Spiral(a0=180u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m" )
    @test abs(s3.pitch - 0.35447u"m/rad") < 1e-4u"m/rad" 
end

@testset "Spiral2D.jl calcPitch()" begin
    # number => number
    p1 = calcPitch(1,2,3,4)
    @test p1 == 1 && typeof(p1) <: Number

    #unitful => unitful
    @test calcPitch(1u"rad",2u"rad",3u"mm",4u"mm") == 1*u"mm/rad"

    #unitful => unitful
    s1 = Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m")
    @test abs(calcPitch(s1) - 1u"m/°") < 1e-4u"m/°"

    # pitch sign convention
    s2 = Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m")
    @test 0u"m/rad" < s2.pitch # r0<r1

    s3 = Spiral(a0=1.1u"°", a1=2.2u"°", r0=5.5u"m", r1=4.4u"m")
    @test 0u"m/rad" > s3.pitch # r0 > r1
end

@testset "Spiral2D.jl increasing/decreasing" begin
    @test isIncreasing( Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m") ) == true
    @test isIncreasing( Spiral(a0=1.1u"°", a1=2.2u"°", r0=5.5u"m", r1=4.4u"m") ) == false
    @test isDecreasing( Spiral(a0=1.1u"°", a1=2.2u"°", r0=5.5u"m", r1=4.4u"m") ) == true
    @test isDecreasing( Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m") ) == false
end

@testset "Spiral2D.jl cw/ccw" begin
    @test isCounterClockwise( Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m") ) == true
    @test isCounterClockwise( Spiral(a0=3.3u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m") ) == false
    @test isClockwise(        Spiral(a0=1.1u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m") ) == false
    @test isClockwise(        Spiral(a0=3.3u"°", a1=2.2u"°", r0=3.3u"m", r1=4.4u"m") ) == true
end


@testset "Spiral2D.jl calcLength()" begin
    s0 = Spiral(a0=1.1u"°", a1=1.1u"°", r0=-3.3u"m", r1=4.4u"m", pitch=5.5u"mm/rad") #nonsense
    @test_logs (:warn, "Spiral2D.calcLength() given r0=$(s0.r0), coerced to 0 as r0 < 0 is nonsensical.") calcLength(s0)

    s1 = Spiral(a0=1.1u"°", a1=1.1u"°", r0=3.3u"m", r1=-4.4u"m", pitch=5.5u"mm/rad") #nonsense
    @test_logs (:warn, "Spiral2D.calcLength() given r1=$(s1.r1), coerced to 0 as r1 < 0 is nonsensical.") calcLength(s1)

    s2 = Spiral(a0=1.1u"°", a1=1.1u"°", r0=3.3u"m", r1=4.4u"m", pitch=5.5u"mm/rad") #straight line
    @test abs(calcLength(s2) - 1.1u"m") < 1e-4u"m"

    s3 = Spiral(a0=0u"°", a1=360u"°", r0=3.3u"m", r1=3.3u"m") #circle circumference
    @test abs(calcLength(s3) - 2*π*3.3u"m") < 1e-4u"m"

    s4 = Spiral(a0=0u"°", a1=360u"°", r0=3.3u"m", r1=4.4u"m") #length is the average circumference
    @test abs(calcLength(s4) - π*3.3u"m" - π*4.4u"m") < 1e-4u"m"

    s5 = Spiral(a0=0u"°", a1=-360u"°", r0=3.3u"m", r1=4.4u"m") #ccw == cw lengths
    @test isapprox( calcLength(s4), calcLength(s5))
    # @test abs(calcLength(s5) - π*3.3u"m" - π*4.4u"m") < 1e-4u"m"
end

@testset "Spiral2D.jl seriesPolar()" begin # not a great test tbh
    s1 = Spiral(a0=0u"°", a1=45u"°", r0=3.0u"m", r1=4.0u"m")
    (as,rs) = seriesPolar(s1, 10)
    @test as == (0:5:45)u"°"
    @test sum(abs.(rs .- (LinRange(3,4,10)*unit(rs[1])) )) < 1e-4u"m"
end

@testset "Spiral2D.jl seriesCartesian()" begin # not a great test tbh
    s1 = Spiral(a0=0u"rad", a1=45u"rad", r0=3.0u"m", r1=4.0u"m")
    n =10
    (xs,ys) = seriesCartesian(s1, n)
    th = LinRange(0,45,n)*u"rad"
    rs = LinRange(3,4,n)*u"m"
    @test sum(abs.( xs .- rs.*cos.(th) )) < 1e-4u"m"
    @test sum(abs.( ys .- rs.*sin.(th) )) < 1e-4u"m"
end
