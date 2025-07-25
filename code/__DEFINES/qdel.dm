//! Defines that give qdel hints.
//!
//! These can be given as a return in [/atom/proc/Destroy] or by calling [/proc/qdel].

/// `qdel` should queue the object for deletion.
#define QDEL_HINT_QUEUE 		0
/// `qdel` should let the object live after calling [/atom/proc/Destroy].
#define QDEL_HINT_LETMELIVE		1
/// Functionally the same as the above. `qdel` should assume the object will gc on its own, and not check it.
#define QDEL_HINT_IWILLGC		2
/// Qdel should assume this object won't GC, and queue a hard delete using a hard reference.
#define QDEL_HINT_HARDDEL		3
// Qdel should assume this object won't gc, and hard delete it posthaste.
#define QDEL_HINT_HARDDEL_NOW	4

//! Defines for the [gc_destroyed][/datum/var/gc_destroyed] var.

#ifdef REFERENCE_TRACKING
/** If REFERENCE_TRACKING is enabled, qdel will call this object's find_references() verb.
 *
 * Functionally identical to [QDEL_HINT_QUEUE] if [GC_FAILURE_HARD_LOOKUP] is not enabled in _compiler_options.dm.
*/
#define QDEL_HINT_FINDREFERENCE	5
/// Behavior as [QDEL_HINT_FINDREFERENCE], but only if the GC fails and a hard delete is forced.
#define QDEL_HINT_IFFAIL_FINDREFERENCE 6
#endif

// Defines for the ssgarbage queues
#define GC_QUEUE_FILTER 1 //! short queue to filter out quick gc successes so they don't hang around in the main queue for 5 minutes
#define GC_QUEUE_CHECK 2 //! main queue that waits 5 minutes because thats the longest byond can hold a reference to our shit.
#define GC_QUEUE_HARDDELETE 3 //! short queue for things that hard delete instead of going thru the gc subsystem, this is purely so if they *can* softdelete, they will soft delete rather then wasting time with a hard delete.
#define GC_QUEUE_COUNT 3 //! Number of queues, used for allocating the nested lists. Don't forget to increase this if you add a new queue stage

// Defines for the time an item has to get its reference cleaned before it fails the queue and moves to the next.
#define GC_FILTER_QUEUE 1 SECONDS
#define GC_CHECK_QUEUE 5 MINUTES
#define GC_DEL_QUEUE 10 SECONDS

// Defines for the [gc_destroyed][/datum/var/gc_destroyed] var.
#define GC_CURRENTLY_BEING_QDELETED -2

#define QDELING(X) (X.gc_destroyed)
#define QDELETED(X) (!X || QDELING(X))
#define QDESTROYING(X) (!X || X.gc_destroyed == GC_CURRENTLY_BEING_QDELETED)
