# nvpmodel — Power Mode Reference

Jetson Orin Nano 8GB power modes. Controls CPU/GPU clock ceilings and TDP.

## Modes

| ID | Name | TDP | GPU Freq | CPU Freq | Use case |
|---|---|---|---|---|---|
| 0 | MAXN | 15W | Max | Max | Heavy inference, compile |
| 1 | 10W | 10W | Reduced | Reduced | Default, battery use |

## Commands

```bash
sudo nvpmodel -q              # query current mode
sudo nvpmodel -m 0            # set MAXN (15W)
sudo nvpmodel -m 1            # set 10W (default)
sudo systemctl enable nvpmodel # persist across reboot
```

## With jetson_clocks

nvpmodel sets the ceiling; jetson_clocks locks clocks to max within that ceiling.
Always set nvpmodel before jetson_clocks:

```bash
sudo nvpmodel -m 0 && sudo jetson_clocks   # maxperf alias
sudo nvpmodel -m 1                          # savepower alias
```

## Monitoring

```bash
sudo jtop    # live GPU/CPU/memory/power dashboard
sudo tegrastats --interval 1000   # raw stats every 1s
```

## Config file

`/etc/nvpmodel.conf` — edited by nvpmodel commands. Do not edit directly.
