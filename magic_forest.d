/**
 * This solves the "Magic Forest" puzzle from the Austrian Mathematical Kangaroo
 * contest.
 * 
 * Original source: https://github.com/logicchains/MagicForest
 * Blog post by the author: http://togototo.wordpress.com/2014/06/20/the-magic-forest-problem-revisited-rehabilitating-java-with-the-aid-of-d/
 * NG discussion: http://forum.dlang.org/thread/lo2ge8$2n0s$1@digitalmars.com
 */
module magic_forest;

/*
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 Jonathan Barnard
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import std.algorithm;
import std.conv;
import std.stdio;
import std.array;
import std.range;
import std.format;

struct forest_t{
  align:
  int goats;
  int wolves;
  int lions;

  forest_t opBinary(string op)(forest_t rhs) pure nothrow if (op == "+") {
    return forest_t(goats+rhs.goats, wolves+rhs.wolves, lions+rhs.lions);
  }
}

void printForest(forest_t forest) {
  writefln("Forest [goats= %d, wolves= %d, lions= %d]", forest.goats, forest.lions, forest.wolves);
}      

bool forest_stable(in immutable forest_t forest) pure nothrow {
  if (forest.goats == 0) return (forest.wolves == 0) || (forest.lions == 0);
  return (forest.wolves == 0) && (forest.lions == 0);
}

bool forest_invalid(in immutable forest_t forest) pure nothrow{
  return (forest.goats < 0 || forest.wolves < 0 || forest.lions < 0);
} 

bool forLessThan(in ref forest_t f1, in ref forest_t f2) pure nothrow {
  bool res = false;
  if(f1.goats == f2.goats){
    if(f1.wolves == f2.wolves){
      if(f1.lions == f2.lions){
    res = false;
      }else{
    res = f1.lions < f2.lions;
      }
    }else {
      res = f1.wolves < f2.wolves;
    }
  }else{
    res = f1.goats < f2.goats;
  }
  return res;
}

forest_t[] meal(forest_t[] forests) {  
  return map!(a => [forest_t(-1, -1, +1)+a, forest_t(-1, +1, -1)+a, forest_t(+1, -1, -1)+a])(forests)
    .join
    .partition!(forest_invalid)
    .sort!(forLessThan, SwapStrategy.stable)
    .uniq
    .array;
}

bool devouring_possible(in forest_t[] forests) pure nothrow {
  return !forests.empty() && !any!forest_stable(forests);
}

forest_t[] stable_forests(forest_t[] forests) {
  return filter!(a => forest_stable(a))(forests).array;
}

auto find_stable_forests(in forest_t forest){
  forest_t[] forests = [forest];
  while(devouring_possible(forests)){
    forests = meal(forests);
  }
  return stable_forests(forests);
}

void main(){
  import std.process;
  auto workFactor = environment.get("DASH_WORK_FACTOR", "1.0").to!double;
  auto initial = cast(int)(100 * workFactor);
  
  immutable forest_t initialForest = {initial, initial, initial};
  forest_t[] stableForests = find_stable_forests(initialForest);
 
  if (stableForests.empty()) {
    "No stable forests found.".writeln;
  }
  else {
    foreach(forest; stableForests){
      printForest(forest);
    }
  } 
}
