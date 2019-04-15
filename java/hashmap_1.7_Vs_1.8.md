#Hashmap

##数据结构

HashMap采用Entry数组来存储key-value对，每一个键值对组成了一个				Entry实体，Entry类实际上是一个单向的链表结构，它具有Next指针，可以连接下一个Entry实体，依次来解决Hash冲突的问题，因为HashMap是按照Key的hash值来计算Entry在HashMap中存储的位置的，如果hash值相同，而key内容不相等，那么就用链表来解决这种hash冲突。在jdk 1.8之后，数据结构由原来的数组+链表的方式，变化为数组+链表+红黑树的存储方式。
![屏幕快照 2019-03-12 下午9.14.35.png](https://upload-images.jianshu.io/upload_images/6753818-679c4d5731d909db.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

参考jdk 1.8源码，在put方法中，当链表节点较少时仍然是以链表存在，当链表节点较多时（大于8）会转为红黑树。

###put方法
```
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
 
// 第三个参数 onlyIfAbsent 如果是 true，那么只有在不存在该 key 时才会进行 put 操作
// 第四个参数 evict 我们这里不关心
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    // 第一次 put 值的时候，会触发下面的 resize()，类似 java7 的第一次 put 也要初始化数组长度
    // 第一次 resize 和后续的扩容有些不一样，因为这次是数组从 null 初始化到默认的 16 或自定义的初始容量
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    // 找到具体的数组下标，如果此位置没有值，那么直接初始化一下 Node 并放置在这个位置就可以了
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
 
    else {// 数组该位置有数据
        Node<K,V> e; K k;
        // 首先，判断该位置的第一个数据和我们要插入的数据，key 是不是"相等"，如果是，取出这个节点
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        // 如果该节点是代表红黑树的节点，调用红黑树的插值方法，本文不展开说红黑树
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            // 到这里，说明数组该位置上是一个链表
            for (int binCount = 0; ; ++binCount) {
                // 插入到链表的最后面(Java7 是插入到链表的最前面)
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    // TREEIFY_THRESHOLD 为 8，所以，如果新插入的值是链表中的第 9 个
                    // 会触发下面的 treeifyBin，也就是将链表转换为红黑树
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                // 如果在该链表中找到了"相等"的 key(== 或 equals)
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    // 此时 break，那么 e 为链表中[与要插入的新值的 key "相等"]的 node
                    break;
                p = e;
            }
        }
        // e!=null 说明存在旧值的key与要插入的key"相等"
        // 对于我们分析的put操作，下面这个 if 其实就是进行 "值覆盖"，然后返回旧值
        if (e != null) {
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    // 如果 HashMap 由于新插入这个值导致 size 已经超过了阈值，需要进行扩容
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```
 Java8 对 HashMap 进行了一些修改，最大的不同就是利用了红黑树，所以其由 数组+链表+红黑树 组成。
根据 Java7 HashMap 的介绍，我们知道，查找的时候，根据 hash 值我们能够快速定位到数组的具体下标，但是之后的话，需要顺着链表一个个比较下去才能找到我们需要的，时间复杂度取决于链表的长度，为 O(n)。
为了降低这部分的开销，在 Java8 中，当链表中的元素超过了 8 个以后，会将链表转换为红黑树，在这些位置进行查找的时候可以降低时间复杂度为 O(logN)。
和 Java7 稍微有点不一样的地方就是，Java7 是先扩容后插入新值的，Java8 先插值再扩容，不过这个不重要。
数组扩容, resize() 方法用于初始化数组或数组扩容，每次扩容后，容量为原来的 2 倍，并进行数据拷贝。

```
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int oldThr = threshold;
    int newCap, newThr = 0;
    if (oldCap > 0) { // 对应数组扩容
        if (oldCap >= MAXIMUM_CAPACITY) {
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        // 将数组大小扩大一倍
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            // 将阈值扩大一倍
            newThr = oldThr << 1; // double threshold
    }
    else if (oldThr > 0) // 对应使用 new HashMap(int initialCapacity) 初始化后，第一次 put 的时候
        newCap = oldThr;
    else {// 对应使用 new HashMap() 初始化后，第一次 put 的时候
        newCap = DEFAULT_INITIAL_CAPACITY;
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }
 
    if (newThr == 0) {
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    threshold = newThr;
 
    // 用新的数组大小初始化新的数组
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab; // 如果是初始化数组，到这里就结束了，返回 newTab 即可
 
    if (oldTab != null) {
        // 开始遍历原数组，进行数据拷贝。
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {
                oldTab[j] = null;
                // 如果该数组位置上只有单个元素，那就简单了，简单迁移这个元素就可以了
                if (e.next == null)
                    newTab[e.hash & (newCap - 1)] = e;
                // 如果是红黑树，具体我们就不展开了
                else if (e instanceof TreeNode)
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                else { 
                    // 这块是处理链表的情况，
                    // 需要将此链表拆成两个链表，放到新的数组中，并且保留原来的先后顺序
                    // loHead、loTail 对应一条链表，hiHead、hiTail 对应另一条链表，代码还是比较简单的
                    Node<K,V> loHead = null, loTail = null;
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    do {
                        next = e.next;
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    if (loTail != null) {
                        loTail.next = null;
                        // 第一条链表
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        // 第二条链表的新的位置是 j + oldCap
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```

#ConcurrentHashMap
jdk 1.7对于ConcurrentHashMap，主要是用了分段锁Segment对HashEntity的控制，允许多个修改操作并发进行，其关键在于使用了锁分离技术。它使用了多个锁来控制对hash表的不同部分进行的修改。内部使用段(Segment)来表示这些不同的部分，每一个segment都是一个HashEntry<K,V>[] table， table中的每一个元素本质上都是一个HashEntry的单向队列。比如table[3]为首节点，table[3]->next为节点1，之后为节点2，依次类推。只要多个修改操作发生在不同的段上，它们就可以并发进行。
![image.png](https://upload-images.jianshu.io/upload_images/6753818-3457e0bda24ee5f7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

 JDK1.8的实现已经摒弃了Segment的概念，而是直接用Node数组+链表+红黑树的数据结构来实现，并发控制使用Synchronized和CAS来操作，整个看起来就像是优化过且线程安全的HashMap，虽然在JDK1.8中还能看到Segment的数据结构，但是已经简化了属性，只是为了兼容旧版本；loadFactor仅用于构造函数中设定初始容量，已经不能影响扩容阈值，JDK1.8中阈值计算基本恒定为0.75；concurrencyLevel只影响初始容量，后续的并发度大小依赖于table数组的大小。
##put方法
```
    public V put(K var1, V var2) {
        return this.putVal(var1, var2, false);
    }

    final V putVal(K var1, V var2, boolean var3) {
        if (var1 != null && var2 != null) {
            int var4 = spread(var1.hashCode());
            int var5 = 0;
            ConcurrentHashMap.Node[] var6 = this.table;

            while(true) {
                int var8;
                while(var6 == null || (var8 = var6.length) == 0) {
                    var6 = this.initTable();
                }

                ConcurrentHashMap.Node var7;
                int var9;
                if ((var7 = tabAt(var6, var9 = var8 - 1 & var4)) == null) {
                    if (casTabAt(var6, var9, (ConcurrentHashMap.Node)null, new ConcurrentHashMap.Node(var4, var1, var2, (ConcurrentHashMap.Node)null))) {
                        break;
                    }
                } else {
                    int var10;
                    if ((var10 = var7.hash) == -1) {
                        var6 = this.helpTransfer(var6, var7);
                    } else {
                        Object var11 = null;
                        synchronized(var7) {
                            if (tabAt(var6, var9) == var7) {
                                if (var10 < 0) {
                                    if (var7 instanceof ConcurrentHashMap.TreeBin) {
                                        var5 = 2;
                                        ConcurrentHashMap.TreeNode var18;
                                        if ((var18 = ((ConcurrentHashMap.TreeBin)var7).putTreeVal(var4, var1, var2)) != null) {
                                            var11 = var18.val;
                                            if (!var3) {
                                                var18.val = var2;
                                            }
                                        }
                                    }
                                } else {
                                    label103: {
                                        var5 = 1;

                                        ConcurrentHashMap.Node var13;
                                        Object var14;
                                        for(var13 = var7; var13.hash != var4 || (var14 = var13.key) != var1 && (var14 == null || !var1.equals(var14)); ++var5) {
                                            ConcurrentHashMap.Node var15 = var13;
                                            if ((var13 = var13.next) == null) {
                                                var15.next = new ConcurrentHashMap.Node(var4, var1, var2, (ConcurrentHashMap.Node)null);
                                                break label103;
                                            }
                                        }

                                        var11 = var13.val;
                                        if (!var3) {
                                            var13.val = var2;
                                        }
                                    }
                                }
                            }
                        }

                        if (var5 != 0) {
                            if (var5 >= 8) {
                                this.treeifyBin(var6, var9);
                            }

                            if (var11 != null) {
                                return var11;
                            }
                            break;
                        }
                    }
                }
            }

            this.addCount(1L, var5);
            return null;
        } else {
            throw new NullPointerException();
        }
    }
```
put的过程可以分成以下六步流程来概述

*  如果没有初始化就先调用initTable（）方法来进行初始化过程
*  如果没有hash冲突就直接CAS插入
*  如果还在进行扩容操作就先进行扩容
*  如果存在hash冲突，就加锁来保证线程安全，这里有两种情况，一种是链表形式就直接遍历到       尾端插入，一种是红黑树就按照红黑树结构插入.
*  最后一个如果该链表的数量大于阈值8，就要先转换成黑红树的结构，break再一次进入循环
*  如果添加成功就调用addCount（）方法统计size，并且检查是否需要扩容

参考文章：
http://www.importnew.com/28263.html
https://blog.csdn.net/qq_36520235/article/details/82417949

