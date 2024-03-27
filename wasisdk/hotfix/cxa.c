#if defined(__wasi__)
extern "C" {
void *
__cxa_allocate_exception(size_t thrown_size) { return NULL; }
void
__cxa_throw(void *thrown_exception, std::type_info *tinfo, void *dest) {}
}
#endif

