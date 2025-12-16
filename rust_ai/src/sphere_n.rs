//! Generates points on n-dimensional spheres.
//!
//! # Algorithm Overview
//!
//! ```text
//!          VdCorput Sequence
//!                 |
//!                 v
//!   [0,1] ------------------> [0,π] -----> Sphere(n)
//!                    Mapping      Interpolation
//! ```
//!
//! This module implements sphere generators for arbitrary dimensions using
//! low-discrepancy sequences.

use crate::VdCorput;
use std::f64::consts::PI;

/// Simple implementation of numpy.linspace
fn linspace(start: f64, stop: f64, num: usize) -> Vec<f64> {
    if num == 1 {
        return vec![start];
    }
    let step = (stop - start) / (num as f64 - 1.0);
    (0..num).map(|i| start + i as f64 * step).collect()
}

/// Simple implementation of numpy.interp for 1D interpolation
fn simple_interp(x: f64, xp: &[f64], yp: &[f64]) -> f64 {
    if x <= xp[0] {
        return yp[0];
    }
    if x >= xp[xp.len() - 1] {
        return yp[yp.len() - 1];
    }

    for i in 0..xp.len() - 1 {
        if xp[i] <= x && x <= xp[i + 1] {
            // Linear interpolation
            let t = (x - xp[i]) / (xp[i + 1] - xp[i]);
            return yp[i] + t * (yp[i + 1] - yp[i]);
        }
    }

    yp[yp.len() - 1] // fallback
}

/// Precomputed tables for sphere generation
struct SphereTables {
    x: Vec<f64>,
    neg_cosine: Vec<f64>,
    sine: Vec<f64>,
    f2: Vec<f64>,
    half_pi: f64,
}

impl SphereTables {
    fn new() -> Self {
        let x = linspace(0.0, PI, 300);
        let neg_cosine = x.iter().map(|&x| -x.cos()).collect();
        let sine = x.iter().map(|&x| x.sin()).collect();
        let f2 = x
            .iter()
            .zip(&neg_cosine)
            .zip(&sine)
            .map(|((&x, &nc), &s)| (x + nc * s) / 2.0)
            .collect();
        let half_pi = PI / 2.0;

        Self {
            x,
            neg_cosine,
            sine,
            f2,
            half_pi,
        }
    }

    fn get(&self) -> (&[f64], &[f64], &[f64], &[f64], f64) {
        (
            &self.x,
            &self.neg_cosine,
            &self.sine,
            &self.f2,
            self.half_pi,
        )
    }
}

/// Thread-safe cached sphere tables
static SPHERE_TABLES: once_cell::sync::Lazy<SphereTables> =
    once_cell::sync::Lazy::new(SphereTables::new);

/// Calculates the table-lookup of the mapping function for n
fn get_tp(n: usize) -> Vec<f64> {
    use once_cell::sync::Lazy;
    use std::sync::Mutex;

    static TP_CACHE: Lazy<Mutex<Vec<Vec<f64>>>> = Lazy::new(|| Mutex::new(Vec::new()));

    let mut cache = TP_CACHE.lock().unwrap();

    // If already computed, return a copy
    if n < cache.len() {
        return cache[n].clone();
    }

    // Ensure cache has entries up to n
    while cache.len() <= n {
        let tables = SPHERE_TABLES.get();
        let x = &tables.0;
        let neg_cosine = &tables.1;
        let sine = &tables.2;

        let new_n = cache.len();
        let tp = if new_n == 0 {
            x.to_vec()
        } else if new_n == 1 {
            neg_cosine.to_vec()
        } else {
            let tp_minus2 = &cache[new_n - 2];
            x.iter()
                .enumerate()
                .map(|(i, _xi)| {
                    ((new_n - 1) as f64 * tp_minus2[i]
                        + neg_cosine[i] * sine[i].powi((new_n - 1) as i32))
                        / new_n as f64
                })
                .collect()
        };
        cache.push(tp);
    }

    cache[n].clone()
}

/// Base trait for sphere generators
pub trait SphereGen {
    /// Generates and returns a vector of values
    fn pop(&mut self) -> Vec<f64>;

    /// Reseeds the generator with a new seed
    fn reseed(&mut self, seed: u32);
}

/// Wrapper for Sphere that implements SphereGen trait
struct SphereWrapper {
    sphere: crate::Sphere,
}

impl SphereWrapper {
    fn new(base: [u32; 2]) -> Self {
        Self {
            sphere: crate::Sphere::new(base),
        }
    }
}

impl SphereGen for SphereWrapper {
    fn pop(&mut self) -> Vec<f64> {
        self.sphere.pop().to_vec()
    }

    fn reseed(&mut self, seed: u32) {
        self.sphere.reseed(seed);
    }
}

/// 3-Sphere sequence generator
///
/// # Examples
///
/// ```
/// use lds_gen::sphere_n::{Sphere3, SphereGen};
/// let mut sgen = Sphere3::new(&[2, 3, 5]);
/// sgen.reseed(0);
/// let point = sgen.pop();
/// assert_eq!(point.len(), 4);
/// ```
pub struct Sphere3 {
    vdc: VdCorput,
    sphere2: SphereWrapper,
    half_pi: f64,
    x: Vec<f64>,
    f2: Vec<f64>,
}

impl Sphere3 {
    /// Creates a new 3-Sphere generator
    ///
    /// # Arguments
    ///
    /// * `base` - Array of 3 integers used as bases for the sequence
    pub fn new(base: &[u32]) -> Self {
        assert!(base.len() >= 3, "Sphere3 requires at least 3 bases");
        let tables = SPHERE_TABLES.get();
        Self {
            vdc: VdCorput::new(base[0]),
            sphere2: SphereWrapper::new([base[1], base[2]]),
            half_pi: tables.4,
            x: tables.0.to_vec(),
            f2: tables.3.to_vec(),
        }
    }
}

impl SphereGen for Sphere3 {
    fn pop(&mut self) -> Vec<f64> {
        let ti = self.half_pi * self.vdc.pop(); // map to [t0, tm-1]
        let xi = simple_interp(ti, &self.f2, &self.x);
        let cosxi = xi.cos();
        let sinxi = xi.sin();

        let sphere2_point = self.sphere2.pop();
        let mut result = Vec::with_capacity(4);
        for &s in &sphere2_point {
            result.push(sinxi * s);
        }
        result.push(cosxi);
        result
    }

    fn reseed(&mut self, seed: u32) {
        self.vdc.reseed(seed);
        self.sphere2.reseed(seed);
    }
}

/// Sphere-N sequence generator for arbitrary dimensions
///
/// # Examples
///
/// ```
/// use lds_gen::sphere_n::{SphereN, SphereGen};
/// let mut sgen = SphereN::new(&[2, 3, 5, 7]);
/// sgen.reseed(0);
/// let point = sgen.pop();
/// assert_eq!(point.len(), 5); // 4 bases produce 5D point
/// ```
pub struct SphereN {
    vdc: VdCorput,
    s_gen: Box<dyn SphereGen>,
    n: usize,
    tp: Vec<f64>,
    tp_start: f64,
    range: f64,
}

impl SphereN {
    /// Creates a new n-sphere generator
    ///
    /// # Arguments
    ///
    /// * `base` - Array of integers used as bases for the sequence
    ///   Length must be at least 3 (produces n+1 dimensional sphere)
    pub fn new(base: &[u32]) -> Self {
        let n = base.len() - 1;
        assert!(n >= 2, "SphereN requires at least 3 bases (n >= 2)");

        let vdc = VdCorput::new(base[0]);

        let s_gen: Box<dyn SphereGen> = if n == 2 {
            Box::new(SphereWrapper::new([base[1], base[2]]))
        } else {
            Box::new(SphereN::new(&base[1..]))
        };

        let tp = get_tp(n);
        let tp_start = tp[0];
        let range = tp[tp.len() - 1] - tp_start;

        Self {
            vdc,
            s_gen,
            n,
            tp,
            tp_start,
            range,
        }
    }
}

impl SphereGen for SphereN {
    fn pop(&mut self) -> Vec<f64> {
        if self.n == 2 {
            let tables = SPHERE_TABLES.get();
            let ti = tables.4 * self.vdc.pop(); // map to [t0, tm-1]
            let xi = simple_interp(ti, tables.3, tables.0);
            let cosxi = xi.cos();
            let sinxi = xi.sin();

            let sphere_point = self.s_gen.pop();
            let mut result = Vec::with_capacity(sphere_point.len() + 1);
            for &s in &sphere_point {
                result.push(sinxi * s);
            }
            result.push(cosxi);
            return result;
        }

        let vd = self.vdc.pop();
        let ti = self.tp_start + self.range * vd; // map to [t0, tm-1]
        let xi = simple_interp(ti, &self.tp, &SPHERE_TABLES.x);
        let sinphi = xi.sin();

        let sphere_point = self.s_gen.pop();
        let mut result = Vec::with_capacity(sphere_point.len() + 1);
        for &s in &sphere_point {
            result.push(s * sinphi);
        }
        result.push(xi.cos());
        result
    }

    fn reseed(&mut self, seed: u32) {
        self.vdc.reseed(seed);
        self.s_gen.reseed(seed);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use approx::assert_relative_eq;

    #[test]
    fn test_linspace() {
        let result = linspace(0.0, 1.0, 5);
        let expected = vec![0.0, 0.25, 0.5, 0.75, 1.0];
        assert_eq!(result.len(), 5);
        for i in 0..5 {
            assert_relative_eq!(result[i], expected[i], epsilon = 1e-10);
        }

        let result = linspace(0.0, 1.0, 1);
        assert_eq!(result, vec![0.0]);

        let result = linspace(-1.0, 1.0, 3);
        let expected = vec![-1.0, 0.0, 1.0];
        for i in 0..3 {
            assert_relative_eq!(result[i], expected[i], epsilon = 1e-10);
        }
    }

    #[test]
    fn test_simple_interp() {
        let xp = vec![0.0, 1.0, 2.0, 3.0];
        let yp = vec![0.0, 2.0, 4.0, 6.0]; // Linear function y = 2x

        let result = simple_interp(0.5, &xp, &yp);
        assert_relative_eq!(result, 1.0, epsilon = 1e-10);

        let result = simple_interp(1.5, &xp, &yp);
        assert_relative_eq!(result, 3.0, epsilon = 1e-10);

        let result = simple_interp(-0.5, &xp, &yp);
        assert_relative_eq!(result, 0.0, epsilon = 1e-10);

        let result = simple_interp(3.5, &xp, &yp);
        assert_relative_eq!(result, 6.0, epsilon = 1e-10);

        let result = simple_interp(2.0, &xp, &yp);
        assert_relative_eq!(result, 4.0, epsilon = 1e-10);
    }

    #[test]
    fn test_get_tp() {
        let tp0 = get_tp(0);
        assert_eq!(tp0.len(), 300);
        assert_relative_eq!(tp0[0], 0.0, epsilon = 1e-10);
        assert_relative_eq!(tp0[tp0.len() - 1], PI, epsilon = 1e-10);

        let tp1 = get_tp(1);
        assert_eq!(tp1.len(), 300);
        assert_relative_eq!(tp1[0], -0.0f64.cos(), epsilon = 1e-10);
        assert_relative_eq!(tp1[tp1.len() - 1], -PI.cos(), epsilon = 1e-10);

        let tp2 = get_tp(2);
        assert_eq!(tp2.len(), 300);
    }

    #[test]
    fn test_sphere3_basic() {
        let mut sgen = Sphere3::new(&[2, 3, 5]);
        sgen.reseed(0);

        let point = sgen.pop();
        assert_eq!(point.len(), 4);

        let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
        assert_relative_eq!(radius_sq, 1.0, epsilon = 1e-10);

        for &coord in &point {
            assert!(-1.0 <= coord && coord <= 1.0);
        }
    }

    #[test]
    fn test_sphere3_consistency() {
        let bases = vec![vec![2, 3, 5], vec![2, 5, 3], vec![3, 2, 7]];

        for base in bases {
            let mut sgen = Sphere3::new(&base);
            sgen.reseed(0);

            let points: Vec<_> = (0..5).map(|_| sgen.pop()).collect();

            for (i, point) in points.iter().enumerate() {
                let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
                assert_relative_eq!(radius_sq, 1.0, epsilon = 1e-10);
                // Additional check with custom message if needed
                if (radius_sq - 1.0).abs() > 1e-10 {
                    panic!(
                        "Base {:?}, Point {}: {:?}, r²={}",
                        base, i, point, radius_sq
                    );
                }
            }
        }
    }

    #[test]
    fn test_sphere3_reseed() {
        let mut sgen = Sphere3::new(&[2, 3, 5]);

        sgen.reseed(0);
        let seq1: Vec<_> = (0..3).map(|_| sgen.pop()).collect();

        sgen.reseed(0);
        let seq2: Vec<_> = (0..3).map(|_| sgen.pop()).collect();

        for i in 0..3 {
            for j in 0..4 {
                assert_relative_eq!(seq1[i][j], seq2[i][j], epsilon = 1e-10);
            }
        }

        sgen.reseed(1);
        let seq3: Vec<_> = (0..3).map(|_| sgen.pop()).collect();

        let mut different = false;
        for i in 0..3 {
            for j in 0..4 {
                if (seq1[i][j] - seq3[i][j]).abs() > 1e-10 {
                    different = true;
                    break;
                }
            }
            if different {
                break;
            }
        }
        assert!(
            different,
            "Sequences with different seeds should be different"
        );
    }

    #[test]
    fn test_spheren_basic() {
        let mut sgen = SphereN::new(&[2, 3, 5, 7]);
        sgen.reseed(0);

        let point = sgen.pop();
        assert_eq!(point.len(), 5);

        let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
        assert_relative_eq!(radius_sq, 1.0, epsilon = 1e-10);
    }

    #[test]
    fn test_spheren_higher_dimensions() {
        let mut sgen = SphereN::new(&[2, 3, 5, 7, 11]);
        sgen.reseed(0);

        let point = sgen.pop();
        assert_eq!(point.len(), 6);

        let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
        assert_relative_eq!(radius_sq, 1.0, epsilon = 1e-10);
    }

    #[test]
    fn test_spheren_reseed() {
        let mut sgen = SphereN::new(&[2, 3, 5, 7]);

        sgen.reseed(0);
        let seq1: Vec<_> = (0..3).map(|_| sgen.pop()).collect();

        sgen.reseed(0);
        let seq2: Vec<_> = (0..3).map(|_| sgen.pop()).collect();

        for i in 0..3 {
            for j in 0..5 {
                assert_relative_eq!(seq1[i][j], seq2[i][j], epsilon = 1e-10);
            }
        }
    }

    #[test]
    fn test_comparison_with_python() {
        // Expected values from Python doctest examples
        let expected_sphere3 = vec![
            0.2913440162992141,
            0.8966646826186098,
            -0.33333333333333337,
            6.123233995736766e-17,
        ];

        let expected_spheren = vec![
            0.4809684718990214,
            0.6031153874276115,
            -0.5785601510223212,
            0.2649326520763179,
            6.123233995736766e-17,
        ];

        let mut sgen3 = Sphere3::new(&[2, 3, 5]);
        sgen3.reseed(0);
        let result3 = sgen3.pop();

        for i in 0..4 {
            assert_relative_eq!(result3[i], expected_sphere3[i], epsilon = 1e-10);
        }

        let mut sgen_n = SphereN::new(&[2, 3, 5, 7]);
        sgen_n.reseed(0);
        let result_n = sgen_n.pop();

        for i in 0..5 {
            assert_relative_eq!(result_n[i], expected_spheren[i], epsilon = 1e-10);
        }
    }

    #[test]
    #[should_panic(expected = "Sphere3 requires at least 3 bases")]
    fn test_sphere3_insufficient_bases() {
        Sphere3::new(&[2, 3]);
    }

    #[test]
    #[should_panic(expected = "SphereN requires at least 3 bases")]
    fn test_spheren_insufficient_bases() {
        SphereN::new(&[2, 3]);
    }
}
