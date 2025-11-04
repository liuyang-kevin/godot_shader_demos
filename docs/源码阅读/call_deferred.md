首先, 查看这个函数, 这个是才是本体;

p 这个尾缀是指针(pointer)的意思
[call_deferredp](core/variant/callable.cpp#L39)

```c++
//core/variant/callable.cpp#L39
void Callable::call_deferredp(const Variant **p_arguments, int p_argcount) const {
	MessageQueue::get_singleton()->push_callablep(*this, p_arguments, p_argcount, true);
}
```

引擎c++源码, 与gd脚本保持了语义一致;

所以在两种语言中,  call_deferred并不是一个函数;

```txt
用户代码调用
├── C++: callable.call_deferred(arg1, arg2)
│   └── 模板函数展开
│       └── call_deferredp(args_ptr, arg_count)
│           └── MessageQueue::push_callablep()
│
└── GDScript: obj.call_deferred("method", arg1, arg2)
    └── GDScript VM 解析
        └── 调用 C++ 的 call_deferredp()
            └── MessageQueue::push_callablep()

消息队列执行阶段（在 Main::iteration() 中）
└── MessageQueue::flush()
    └── 取出存储的 Callable 和参数
        └── Callable::callp() 执行实际调用
            ├── C++ 对象方法调用
            └── GDScript 函数调用（通过绑定）
```

# c++ 版本
这里使用了一个template写法, 在编译的时候, 生成具体的参数长度的二进制函数, 从而可变长参数列表;
```c++
template <typename... VarArgs>
void call_deferred(VarArgs... p_args) const {
    Variant args[sizeof...(p_args) + 1] = { p_args..., 0 }; // +1 makes sure zero sized arrays are also supported.
    const Variant *argptrs[sizeof...(p_args) + 1];
    for (uint32_t i = 0; i < sizeof...(p_args); i++) {
        argptrs[i] = &args[i];
    }
    return call_deferredp(sizeof...(p_args) == 0 ? nullptr : (const Variant **)argptrs, sizeof...(p_args));
}
```