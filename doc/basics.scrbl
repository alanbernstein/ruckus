#lang scribble/manual

@(require pict)

@title{Ruckus Language Basics}

@defmodule[ruckus #:lang]
@require[(for-label ruckus)]

@section{3D Primitives}

3D objects are, by default, always placed at the origin.  Use @racket[at] or
other transforms to place them where they're needed.

@defproc*[([(sphere [radius real?]) void?]
           [(sphere [#:radius radius real?]) void?]
           [(sphere [#:diameter diameter real?]) void?])]{
  Generates a sphere, centered at the origin, with its size specified by either
  @racket[radius] or @racket[diameter].
}

@defproc[(rects [size-x real?]
                [size-y real?]
                [size-z real?]) void?]{
  Generates a rectangular solid, centered around the origin, with the extent
  along each axis given by @racket[size-x], @racket[size-y], and
  @racket[size-z].
}

@defproc*[([(cube [size real?]) void?])]{
  Shorthand for a rectangular solid that is the same size along each axis, i.e.
  a cube.

  This is exactly equivalent to the following definition:

  @codeblock{
    (define (cube size)
      (rects size size size))
  }
}

@defproc*[([(capsule [height real?] [radius real?]) void?])]{
  A capsule is like a cylinder, but its ends are rounded like spheres instead
  of flat.

  The @racket[capsule] form generates a capsule, centered around the origin,
  and extending along the Z axis.  @racket[height] gives the distance between
  the center points of the two ending spheres, and @racket[radius] gives the
  radius of the capsule and the ending spheres.

  Note that the actual length of a capsule along Z is given by @racket[(+
  height (* 2 radius))].
}

@defproc*[([(half-space [normal coord?] [distance real?]) void?])]{
  Generates a half-space, which divides all of space into two sections (inside
  and outside) split by a plane.

  The plane's normal is given by @racket[normal], and its distance from the
  origin along the normal is @racket[distance].  Positive distances include the
  origin in the "inside" part of space; negative distances exclude it.
}

@defform[(interpolation-surface constraints)]{
  Generates an interpolated implicit surface using Turk's algorithm for least
  curvature given the surface @racket[constraints].

  @racket[constraints] must be a list.  Each item in the list can be one of two
  kinds, basic points and points with normal vectors.

  Basic points (as lists of three reals) are points in space that are on the
  surface of the object.

  Points with normals are given as a list of two points.  The first is a basic
  point on the surface, and the second is taken as a normal vector pointing
  out of the surface at that point.

  At least one point in the @racket[constraints] list must have a normal.

  This is still under development and is pretty hairy.
}

@section{2D Primitives}

@defproc*[([(circle [radius real?]) void?]
           [(circle [#:radius radius real?]) void?]
           [(circle [#:diameter diameter real?]) void?])]{
  Generates a circle whose size is specified by either @racket[radius] or
  @racket[diameter].
}

@defproc*[([(rect [size-x real?]
                  [size-y real?]) void?])]{
  Generates a rectangle, centered around the origin, whose dimensions on the X
  and Y axis are given by @racket[size-x] and @racket[size-y], respectively.
}

@section{Combinators}

@defform[(union form ...)]{
  Combines all its child forms so that they act as a single object.  The result
  is as if each of the children were simply overlaid on the others: any piece
  that is solid in at least one child is also solid in the union.

  Most combinators implicitly union their children, so an @italic{explicit}
  union is rarely necessary.

  @codeblock{
    (union
      (cube 330)
      (sphere 200))
  }

  @bitmap{doc/example-union.png}
}

@defform[(intersection form ...)]{
  Intersects all its child forms.  The result is solid only in those areas that
  are solid in @italic{all} child forms.

  @codeblock{
    (intersection
      (cube 330)
      (sphere 200))
  }

  @bitmap{doc/example-intersection.png}
}

@defform[(difference first-form other-forms ...)]{
  Starting with the @racket[first-form], subtracts each of the
  @racket[other-forms].  Areas are solid in the result only if they are solid in
  @racket[first-form] and @italic{not solid} in any of @racket[other-forms].

  Unlike @racket[intersection], @racket[difference] is sensitive to the order of
  its child forms.  The @racket[first-form] is treated specially.  As a result,
  using @racket[difference] is the main case where you may want to use an
  explicit @racket[union] to group several objects together into a single form.

  @codeblock{
    (difference
      (cube 330)
      (sphere 200))
  }

  @bitmap{doc/example-difference.png}
}

@defform[(smooth-union radius form ...)]{
  Like @racket[union], but the creases where the child forms would intersect
  are rounded to a minimum curvature @racket[radius].

  @codeblock{
    (smooth-union 10
      (cube 330)
      (sphere 200))
  }

  @bitmap{doc/example-smooth-union.png}
}

@section{Transforms}

@defform[(at vector forms ...)]{
  Shifts child forms so that their origin is at the point @racket[vector] in the
  current coordinate space.

  @racket[vector] should be a valid vector in the current context: in 3D, a
  list of three real numbers; in 2D, a list of two.  @racket[vector] may be
  written in place as a literal, or taken from a variable.

  @racket[at] implicitly wraps its children in a @racket[union].

  @racket[translate] is a synonym for @racket[at].

  @codeblock{
    (at '[0 100 0]
      (cube 330)
      (sphere 200))
  }
}

@defform[(translate vector forms ...)]{
  @racket[translate] is a wordy synonym for @racket[at].
}

@defform*[((scale ratio forms ...)
           (scale vector forms ...))
          #:contracts ([ratio real?] [vector (listof real?)])]{
  Adjusts the size of child forms around their common origin.

  When called with @racket[ratio], the single ratio is applied equally to all
  axes.

  When called with @racket[vector], separate ratios are applied to each axis:
  in 3D contexts, three ratios are required, and in 2D, two are required.

  @racket[scale] implicitly wraps its children in a @racket[union].

  @codeblock{
    (scale 1/2 (sphere 200))
    (scale '[1 1/2 1/5] (cube 330))
  }

  @bitmap{doc/example-scale.png}
}

@defform*[((rotate angle forms ...)
           (rotate angle #:around axis forms ...))
         #:contracts ([angle real?] [axis (listof real?)])]{
  Rotates child forms around their common origin.

  In 2D contexts, the first version must be used, and the rotation is always
  counter-clockwise by @racket[angle] degrees around the Z axis.

  In 3D contexts, the second version must be used, and the @racket[axis]
  must be provided.

  @racket[axis] can be one of the literal symbols @racket['x], @racket['y],
  or @racket['z], designating the X, Y, or Z axes, respectively.

  @racket[axis] can also be a literal vector, given as a list of three numbers.
  In this case the vector will be normalized internally.

  @racket[rotate] implicitly wraps its children in a @racket[union].

  @codeblock{
    (rotate 45 #:around 'z
      (sphere 200)
      (cube 330))
  }
}

@defform[(color col forms ...)
         #:contracts ([col (listof real?)])]{
  Assigns a color to child forms.

  The color @racket[col] is represented as a list of real numbers,
  giving the fraction of red, green, and blue as a number between
  0 and 1.

  Color is currently only significant in the Ruckus visualizer.

  @codeblock{
    (color '[0 0 1]
      (sphere 200)
      (cube 330))
  }
}

@defform[(iso shift forms ...)
         #:contracts ([shift real?])]{
  Applies an @italic{isolevel shift} to child forms, which will outset their
  surfaces if @racket[shift] is positive, or inset if @racket[shift] is
  negative.

  @codeblock{
    (iso +20
      (cube 330))
  }

  @bitmap{doc/example-iso.png}
}

@defform[(extrude height forms ...)
         #:contracts ([height real?])]{
  Extrudes 2D child forms along the Z axis into a 3D solid of height
  @racket[height] centered around the XY plane.

  To apply @racket[extrude] to 3D child forms, you must combine it with
  @racket[slice], as shown in the example below.

  @codeblock{
    (extrude 200
      (at '[100 0]
        (circle 100)))
    (extrude 40
      (slice
        (at '[-100 0 0]
          (cube 200))))
  }

  @bitmap{doc/example-extrude.png}
}

@defform[(slice forms ...)]{
  Converts 3D forms into 2D by intersecting them with the XY plane.  This is
  useful to convert an arbitrary cross-section of a 3D object into a 2D outline,
  which can then be manipulated or extruded.
}

@defform[(mirror-x forms ...)]{
  Mirrors child forms around the YZ plane, causing the result to be symmetric
  along the X axis and symmetric around the YZ plane.
}

@defform[(mirror-y forms ...)]{
  Mirrors child forms around the XZ plane, causing the result to be symmetric
  along the Y axis and symmetric around the XZ plane.
}

@defform[(mirror-z forms ...)]{
  Mirrors child forms around the XY plane, causing the result to be symmetric
  along the Z axis and symmetric around the XY plane.

  This version is illegal in 2D contexts, since there is no Z axis.
}

@defform*[((repeat-x period forms ...))]{
  Takes a @racket[period]-unit-wide slice of the child forms around the YZ
  plane and repeats it infinitely along the X axis.
}

@defform[(radial-repeat count forms ...)]{
  Makes the child forms @racket[count]-way radially symmetric around the Z
  axis.
}
