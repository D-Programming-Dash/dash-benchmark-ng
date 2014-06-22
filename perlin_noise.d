/**
 * This benchmarks an algorithm for creating a 2D array of Perlin noise.
 *
 * Sensitive to inlining and the performance of floor(). 
 * 
 * Original source: https://github.com/nsf/pnoise#readme
 * Reddit discussion: http://www.reddit.com/r/rust/comments/289enx/c0de517e_where_is_my_c_replacement/cibn6sr
 * NG discussion: http://forum.dlang.org/thread/lo19l7$n2a$1@digitalmars.com
 */
module perlin_noise;

import std.stdio;
import std.random;
import std.math;

struct Vec2 {
    float x, y;
}

float lerp(float a, float b, float v) pure @safe nothrow
{
    return a * (1 - v) + b * v;
}

float smooth(float v) pure @safe nothrow
{
    return v * v * (3 - 2 * v);
}

Vec2 random_gradient(Random)(ref Random r)
{
    auto v = uniform(0.0f, cast(float)PI * 2.0f, r);
    return Vec2(cos(v), sin(v));
}

float gradient(Vec2 orig, Vec2 grad, Vec2 p) pure @safe nothrow
{
    auto sp = Vec2(p.x - orig.x, p.y - orig.y);
    return grad.x * sp.x + grad.y * sp.y;
}

struct Noise2DContext {
    Vec2[256] rgradients;
    uint[256] permutations;
    Vec2[4] gradients;
    Vec2[4] origins;

private:
    Vec2 get_gradient(int x, int y) pure @safe nothrow
    {
        auto idx = permutations[x & 255] + permutations[y & 255];
        return rgradients[idx & 255];
    }

    void get_gradients(float x, float y) @safe nothrow
    {
        float x0f = floor(x);
        float y0f = floor(y);
        int x0 = cast(int)x0f;
        int y0 = cast(int)y0f;
        int x1 = x0 + 1;
        int y1 = y0 + 1;

        gradients[0] = get_gradient(x0, y0);
        gradients[1] = get_gradient(x1, y0);
        gradients[2] = get_gradient(x0, y1);
        gradients[3] = get_gradient(x1, y1);

        origins[0] = Vec2(x0f + 0.0f, y0f + 0.0f);
        origins[1] = Vec2(x0f + 1.0f, y0f + 0.0f);
        origins[2] = Vec2(x0f + 0.0f, y0f + 1.0f);
        origins[3] = Vec2(x0f + 1.0f, y0f + 1.0f);
    }

public:
    static Noise2DContext opCall(uint seed)
    {
        Noise2DContext ret;
        auto rnd = Random(seed);
        foreach (ref elem; ret.rgradients)
            elem = random_gradient(rnd);

        foreach (i; 0 .. ret.permutations.length) {
            uint j = uniform(0, cast(uint)i+1, rnd);
            ret.permutations[i] = ret.permutations[j];
            ret.permutations[j] = cast(uint)i;
        }

        return ret;
    }

    float get(float x, float y) @safe nothrow
    {
        auto p = Vec2(x, y);

        get_gradients(x, y);
        auto v0 = gradient(origins[0], gradients[0], p);
        auto v1 = gradient(origins[1], gradients[1], p);
        auto v2 = gradient(origins[2], gradients[2], p);
        auto v3 = gradient(origins[3], gradients[3], p);

        auto fx = smooth(x - origins[0].x);
        auto vx0 = lerp(v0, v1, fx);
        auto vx1 = lerp(v2, v3, fx);
        auto fy = smooth(y - origins[0].y);
        return lerp(vx0, vx1, fy);
    }
}


void main()
{
    import std.conv;
    import std.process;
    auto workFactor = environment.get("DASH_WORK_FACTOR", "1.0").to!double;
    auto size = cast(size_t)(256 * workFactor);

    immutable symbols = [" ", "░", "▒", "▓", "█", "█"];
    auto pixels = new float[size*size];

    auto n2d = Noise2DContext(0);
    foreach (i; 0..100) {
        foreach (y; 0..size) {
            foreach (x; 0..size) {
                auto v = n2d.get(x * 0.1f, y * 0.1f) *
                    0.5f + 0.5f;
                pixels[y*size+x] = v;
            }
        }
    }

    foreach (y; 0..size) {
        foreach (x; 0..size) {
            write(symbols[cast(int)(pixels[y*size+x] / 0.2f)]);
        }
        writeln();
    }
}
