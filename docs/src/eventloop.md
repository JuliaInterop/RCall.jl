# Eventloop

In a non-IJulia interactive session, by R will by default open a new window to display the plot. In order to enable interactive features, such as plot-resizing, the R eventlopp will be started automatically.

You could start manually the R event loop via

```julia
RCall.rgui_start()
```

This runs frequent calls to R to check if the plot has changed, and redraw if necessary. It can be stopped with

```julia
RCall.rgui_stop()
```
