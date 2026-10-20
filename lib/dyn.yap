

use "lib/chunk.yap"
use "lib/bool.yap"


seq Dyn
{
    SIZE,
    CAPACITY,
    CONTAINER,
}

fn Dyn::Size(list)
{
    return list.Dyn::SIZE;
}
fn Dyn::Ptr(list)
    // shorthand for get/set access.
{
    return list.Dyn::CONTAINER;
}


fn Dyn::CreatePopulate(size, capacity, container)
{
    put list = Chunk::New(Dyn);
    put list.Dyn::SIZE      = size;
    put list.Dyn::CAPACITY  = capacity;
    put list.Dyn::CONTAINER = container;
    return list;
}

fn Dyn::CreatePreAlloc(words)
{
    return Dyn::CreatePopulate(
        0,
        words,
        Chunk::New(words),
    );
}


fn Dyn::Create()
{
    return Dyn::CreatePreAlloc(1);
}


fn Dyn::Void(list)
{
    Chunk::Void(list.Dyn::CONTAINER);
    Chunk::Void(list);
}



fn Dyn::Recap(list, cap)
{
    jump invalid ~ cap < list.Dyn::SIZE;

    put container = Chunk::New(cap);

    Mem::Cpy(
        container,
        list.Dyn::CONTAINER,
        list.Dyn::SIZE,
    );

    Chunk::Void(list.Dyn::CONTAINER);

    put list.Dyn::CAPACITY  = cap;
    put list.Dyn::CONTAINER = container;

    return Bool::TRUE;

lab invalid;
    return Bool::FALSE;
}


fn Dyn::Local::EnsureSize(list, size)
{
    jump fine ~ (list.Dyn::CAPACITY) > (size - 1);
        // can never error for obvious reasons 
        Dyn::Recap(
             list,
            (list.Dyn::CAPACITY) * 2,
        ); 
    lab fine; 
}

fn Dyn::Insert(list, index, elem)
    // returns success.
    // only failure is bounds violation. 
{
    put new_size = (list.Dyn::SIZE) + 1;
    Dyn::Local::EnsureSize(list,new_size);

    jump out_of_bounds ~ index > (list.Dyn::SIZE);
    put pos = (list.Dyn::CONTAINER) : index;

    Mem::CpyB(
        pos : 1, pos,
        (list.Dyn::SIZE) - index,
    );

    put (list.Dyn::CONTAINER).index = elem;
    put list.Dyn::SIZE = new_size;

    return Bool::TRUE;
lab out_of_bounds;
    return Bool::FALSE;
}



fn Dyn::Erase(list, index)
    // returns success.
    // only failure is bounds violation. 
{
    jump out_of_bounds ~ (list.Dyn::SIZE) == 0;
    put new_size = (list.Dyn::SIZE) - 1;
    put pos = (list.Dyn::CONTAINER) : index;

    Mem::CpyF(
        pos, pos : 1,
        new_size - index,
    );

    put list.Dyn::SIZE = new_size;
    
    return Bool::TRUE;
lab out_of_bounds;
    return Bool::FALSE;
}


fn Dyn::Push(list, elem)
    // push to end of list.
{
    return Dyn::Insert(
        list,
        list.Dyn::SIZE,
        elem,
    );
}

fn Dyn::Pop(list)
    // pop from end of list.
{
    jump empty ~ (list.Dyn::SIZE) == 0;

    put new_size = (list.Dyn::SIZE) - 1;
    put elem = Dyn::Ptr(list).new_size;
    put list.Dyn::SIZE = new_size;
    return elem;

lab empty;
    return Mem::NULL;
}



fn Dyn::Merge(list, other)
{
    put list_size  = Dyn::Size(list);
    put other_size = Dyn::Size(other);
    jump skip ~ other_size == 0; // nothing to merge.

    put new_size = list_size + other_size;
    Dyn::Local::EnsureSize(list, new_size);

    put other_container = Dyn::Ptr(other);

    put i = 0;
    lab loop;
        put elem = other_container.i;
        Dyn::Push(list, elem);
        put i = i + 1;
    jump loop ~ i < other_size;

lab skip;
}



