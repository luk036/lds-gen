//! Integer Low-Discrepancy Sequence (ILDS) Generator
//!
//! This module implements integer versions of low-discrepancy sequence generators:
//! the Van der Corput sequence and the Halton sequence for integer output.
//! These sequences are used to generate evenly distributed points in a space,
//! which can be useful for various applications like sampling, optimization,
//! or numerical integration.

/// Integer Van der Corput sequence generator
///
/// Generates integer values of the Van der Corput sequence with a specified scale.
///
/// # Examples
///
/// ```
/// use lds_gen::ilds::VdCorput;
/// let mut vdc = VdCorput::new(2, 10);
/// vdc.reseed(0);
/// assert_eq!(vdc.pop(), 512); // 0.5 * 2^10 = 512
/// ```
pub struct VdCorput {
    base: u32,
    #[allow(dead_code)] // Used for documentation and API consistency
    scale: u32,
    count: u32,
    factor: u32,
}

impl VdCorput {
    /// Creates a new integer Van der Corput sequence generator
    ///
    /// # Arguments
    ///
    /// * `base` - The base of the number system (defaults to 2 if not specified)
    /// * `scale` - The scale factor determining the number of digits that can be represented
    pub fn new(base: u32, scale: u32) -> Self {
        let factor = base.pow(scale);
        Self {
            base,
            scale,
            count: 0,
            factor,
        }
    }
    
    /// Generates the next integer value in the sequence
    ///
    /// Increments the count and calculates the next integer value
    /// in the Van der Corput sequence.
    pub fn pop(&mut self) -> u32 {
        self.count += 1;
        let mut k = self.count;
        let mut vdc = 0;
        let mut factor = self.factor;
        
        while k != 0 {
            factor /= self.base;
            let remainder = k % self.base;
            k /= self.base;
            vdc += remainder * factor;
        }
        vdc
    }
    
    /// Resets the state of the sequence generator to a specific seed value
    ///
    /// # Arguments
    ///
    /// * `seed` - The seed value that determines the starting point of the sequence generation
    pub fn reseed(&mut self, seed: u32) {
        self.count = seed;
    }
}

impl Default for VdCorput {
    fn default() -> Self {
        Self::new(2, 10)
    }
}

/// Integer Halton sequence generator
///
/// Generates points in a 2-dimensional space using integer Halton sequences.
///
/// # Examples
///
/// ```
/// use lds_gen::ilds::Halton;
/// let mut hgen = Halton::new([2, 3], [11, 7]);
/// hgen.reseed(0);
/// let res = hgen.pop();
/// assert_eq!(res[0], 1024); // 0.5 * 2^11 = 1024
/// assert_eq!(res[1], 729);  // 1/3 * 3^7 = 729
/// ```
pub struct Halton {
    vdc0: VdCorput,
    vdc1: VdCorput,
}

impl Halton {
    /// Creates a new integer Halton sequence generator with the given bases and scales
    ///
    /// # Arguments
    ///
    /// * `base` - An array of two integers used as bases for generating the sequence
    /// * `scale` - An array of two integers used as scales for each dimension
    pub fn new(base: [u32; 2], scale: [u32; 2]) -> Self {
        Self {
            vdc0: VdCorput::new(base[0], scale[0]),
            vdc1: VdCorput::new(base[1], scale[1]),
        }
    }
    
    /// Generates the next point in the integer Halton sequence
    ///
    /// Returns the next point as a `[u32; 2]`.
    pub fn pop(&mut self) -> [u32; 2] {
        [self.vdc0.pop(), self.vdc1.pop()]
    }
    
    /// Resets the state of the sequence generator to a specific seed value
    ///
    /// # Arguments
    ///
    /// * `seed` - The seed value that determines the starting point of the sequence generation
    pub fn reseed(&mut self, seed: u32) {
        self.vdc0.reseed(seed);
        self.vdc1.reseed(seed);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ilds_vdcorput_pop() {
        let mut vdc = VdCorput::new(2, 10);
        vdc.reseed(0);
        assert_eq!(vdc.pop(), 512); // 0.5 * 1024
        assert_eq!(vdc.pop(), 256); // 0.25 * 1024
        assert_eq!(vdc.pop(), 768); // 0.75 * 1024
        assert_eq!(vdc.pop(), 128); // 0.125 * 1024
    }

    #[test]
    fn test_ilds_vdcorput_reseed() {
        let mut vdc = VdCorput::new(2, 10);
        vdc.reseed(5);
        assert_eq!(vdc.pop(), 384); // 0.375 * 1024
        vdc.reseed(0);
        assert_eq!(vdc.pop(), 512); // 0.5 * 1024
    }

    #[test]
    fn test_ilds_vdcorput_default() {
        let mut vdc = VdCorput::default();
        vdc.reseed(0);
        assert_eq!(vdc.pop(), 512);
        assert_eq!(vdc.pop(), 256);
    }

    #[test]
    fn test_ilds_halton_pop() {
        let mut hgen = Halton::new([2, 3], [11, 7]);
        hgen.reseed(0);
        let res = hgen.pop();
        assert_eq!(res[0], 1024); // 0.5 * 2048
        assert_eq!(res[1], 729);  // 1/3 * 2187
        
        let res = hgen.pop();
        assert_eq!(res[0], 512);  // 0.25 * 2048
        assert_eq!(res[1], 1458); // 2/3 * 2187
    }
}