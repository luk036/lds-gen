"""Verify LDS output matches across languages."""
from lds_gen.lds import Circle, Halton, Sphere, Sphere3Hopf, VdCorput

print("=== VdCorput base=2, first 10 values ===")
v = VdCorput(2)
v.reseed(0)
vals = [v.pop() for _ in range(10)]
print(vals)

print("\n=== Halton bases=[2,3], first 5 points ===")
h = Halton([2, 3])
h.reseed(0)
pts = [h.pop() for _ in range(5)]
print(pts)

print("\n=== Circle base=2, first 5 points ===")
c = Circle(2)
c.reseed(0)
pts = [c.pop() for _ in range(5)]
print(pts)

print("\n=== Sphere bases=[2,3], first 3 points ===")
s = Sphere([2, 3])
s.reseed(0)
pts = [s.pop() for _ in range(3)]
print(pts)

print("\n=== Sphere3Hopf bases=[2,3,5], first 3 points ===")
h3 = Sphere3Hopf([2, 3, 5])
h3.reseed(0)
pts = [h3.pop() for _ in range(3)]
print(pts)
