## MY PRETTY MONITORING SCRIPT WITH LOGGING

Thanks to [bobdobs](https://github.com/bobdobs/cardano-scripts) for making this script. I've taken his work and added my own something-something to it to make it work "better" and look "prettier".

### STEP 1: PUT JORMUNGANDR IN YOUR PATH

You need to put Jormungandr into your path so you can just type "jormungandr" anywhere to run it. To do that you need to edit your **.profile** file in your home directory.

`export PATH=$PATH:/path/to/jormungandr:/path/to/jcli`

### STEP 2: SETUP JORMUNGANDR SERVICE

First you need to setup Jormungandr to run as a service. You want to do this because if your node becomes unresponsive, using the JCLI to connect and shutdown the node is not going to work. You won't be able to reset your node.

If your system uses **systemctl** to start and stop services, then you'll need to edit the file: 

```/etc/systemd/system/jorg.service``` 

Yyou will want to create the file jorg.service, it doesn't exist. And we're calling it 'jorg' because its easy to remember and quick to type (service jorg start|stop|restart).

```
[Unit]
Description=Jormungandr
After=multi-user.target

[Service]
Type=simple
ExecStart=jormungandr --config /path/to/config-file --genesis-block-hash replacethiswithgenesisblockhash --secret /path/to/node-secret-key

LimitNOFILE=16384

Restart=on-failure
RestartSec=5s
User=YOURUSERNAME
Group=YOURUSERSGROUP

[Install]
WantedBy=multi-user.target
```

Once thats done you need to reload the changes: **systemctl daemon-reload && systemctl enable jorg && systemctl start jorg**

### STEP 3: RUN THE JORG SERVICE AS SUDO WITHOUT A PASSWORD

Since Jormungandr (jorg) is a service you need to be sudo to run it and its going to totally ruin your day to come back to your server only to see the monitor is stuck asking for a password to reset jorg. So here is what you need to do, if your user is not already in the sudo group, as root do this: **usermod -aG sudo USERNAME**

Next, youll need to do: 

```sudo visudo -f /etc/sudoers.d/YOURUSERNAME```

This is going to create a file that contains your overrides for the sudo command. In the editor thats opened with the above command put this: 

```YOURUSERNAME ALL = (root) NOPASSWD: /usr/sbin/service```

This will allow you to run the service command without asking for a password. This is only going to let you use that one command without a password, nothing else. 

### STEP 4: MONITORING & LOGGING

Copy the script to /bin or somewhere in your path. The script outputs to the screen and runs in a loop. It also outputs the same info to a log file so you can review it later. You will want to edit the **${LOG_FILE}** variable to set where to store your logs. The script will run until you stop it.

Here is a sample of the output: 

```
DATE: Today's date
EP: Epoch
SLOT: Current Slot
EXP. TIME: Last Block Time @ Shelley Explorer
LOCAL TIME: Last Block Time @ localhost
SHLLY: Shelley Chain Height
LOCAL Local Chain Height
POOLTL: Consensus Chain Height @ Pooltool.io
LAST HASH: Last Block Hash
CNT: Events since last reset


===DATE===      EP   SLOT      EXP. TIME      LOCAL TIME     DIFFS     SHLLY     LOCAL     POOLTL    HASH      FORK     CNT 
2020-01-20      37   17628     05:01:13       05:01:18       -5s       114050    114050    114048    2f9cb     NO        127
2020-01-20      37   17657     05:02:11       05:02:12       -1s       114050    114051    114050    1424b     NO        128
2020-01-20      37   17674     05:02:45       05:02:48       -3s       114054    114054    114050    6dddd     YES       129
2020-01-20      37   17683     05:03:03       05:03:07       -4s       114055    114055    114054    a102f     NO        130
2020-01-20      37   17691     05:03:19       05:03:29       -10s      114050    114056    114054    1c23b     NO        131
2020-01-20      37   17693     05:03:23       05:03:39       -16s      114052    114057    114054    2cb7e     NO        132
2020-01-20      37   17713     05:04:03       05:04:07       -4s       114058    114058    114057    a5392     NO        133
2020-01-20      37   17739     05:04:55       05:04:58       -3s       114057    114060    114059    c5b3c     YES       134
2020-01-20      37   17802     05:07:01       05:07:08       -7s       114061    114061    114060    7e0dc     NO        135
2020-01-20      37   17842     05:08:21       05:08:21       -----     114065    114064    114063    31e63     YES       136
2020-01-20      37   17849     05:08:35       05:08:38       -3s       114062    114066    114063    3881d     YES       137
2020-01-20      37   17892     05:10:01       05:10:06       -5s       114069    114069    114067    8c2ac     YES       138
2020-01-20      37   17912     05:10:41       05:10:43       -2s       114065    114070    114068    d82ce     NO        139
2020-01-20      37   18024     05:14:25       05:14:31       -6s       114072    114072    114070    9a5bc     YES       140
2020-01-20      37   18031     05:14:39       05:14:43       -4s       114073    114073    114070    26651     NO        141
2020-01-20      37   18072     05:16:01       05:16:02       -1s       114075    114075    114074    1b980     YES       142
2020-01-20      37   18087     05:16:31       05:16:32       -1s       114076    114076    114074    3ffa8     NO        143


```
