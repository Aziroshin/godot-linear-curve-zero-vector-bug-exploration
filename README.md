# godot-linear-curve-zero-vector-bug-exploration

An exploration of the godot bug described in issue #...

All the code is in [root.gd](root.gd), with comments to guide the exploration process a bit. It's structured into various functions to make it easy to play around and poke at the problem, as well as visualize the curve and its control points.

There's one scene, [root.tscn](root.tscn), which contains a visualized curve with 5 points. `_ready` goes through various functions to set it up, with comments as to where the bug occurs, with some of them commented out with descriptions as to what kind of bug behaviour is to be expected when enabling them.

There are also two functions with self-contained code to trigger the issue, without visualization: `standalone_trigger_curve2d` and `standalone_trigger_curve3d`.
