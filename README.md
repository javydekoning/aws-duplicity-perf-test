# Test results duplicity

**Seconds to backup/restore 672926 files 72G via Duplicity**
Dataset used for testing:
https://www.kaggle.com/datasets/allen-institute-for-ai/CORD-19-research-challenge

|--------------------------------------------------------------|--------|--------|---------|--------|
|                                                              |        |        |         |        |
|                                                              | Backup |        | Restore |        |
|                                                              | Docker | Native | Docker  | Native |
| **c6a.large**                                                | 4182   | 3976   | 810     | 695    |
| **c6g.large**                                                | 3872   | 3852   | 901     | 787    |
| **c6i.large**                                                | 3556   | 3215   | 789     | 631    |
| **c6i.xlarge**                                               | 3315   | 3030   | 737     | 604    |
| **c7g.large**                                                | 3242   | 3210   | 714     | 632    |
| **m5zn.2xlarge**                                             | 2766   | 2714   | 716     | 610    |
| **m5zn.large**                                               | 2817   | 2784   | 693     | 574    |
| **m5zn.xlarge**                                              | 2817   | 2782   | 690     | 589    |
| **r6i.large**                                                | 3314   | 3026   | 759     | 622    |
| **x2iedn.xlarge**                                            | 2791   | 2472   | 670     | 523    |


## Additional notes / tools

Other tools I've considered:

### Kopia

Found at https://kopia.io/docs/ https://github.com/kopia/kopia 

Faster backup performance. Main contributor seems to be the option to use [zstd](https://facebook.github.io/zstd/) compression. 
Written in Go, multi-threaded, support for running in container. 

Can mount backups (snapshots) for file-level restore. 

This would be my tool of choice, however it hasn't reached it's first major version and they only support `+|-` one minor version today. Hence, a concern for storing long-term backups today.

```
kopia repository create filesystem --path /tmp/my-repository 
kopia repository connect filesystem --path /tmp/my-repository
kopia policy set --global --compression=zstd
kopia snapshot create $HOME/Projects/github.com/kopia/kopia --parallel=8
```

### Duplicati2

Not GA, slow release cycle unless when using canary (which might break). Can run in Container, but 
Duplicati team doesn’t maintain their own images.