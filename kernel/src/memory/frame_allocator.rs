pub struct FrameAllocator;

impl FrameAllocator {
    pub fn new() -> Self {
        FrameAllocator
    }

    pub fn allocate(&mut self) -> Option<usize> {
        None
    }
}
