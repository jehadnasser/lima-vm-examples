# Example: Run K3s in an Ubuntu VM with Lima

## How to Install and Use Lima
Check out my article on Medium [here](https://medium.com/@jehadnasser/sick-of-running-vagrant-on-apple-silicon-meet-lima-efc41994bb21)

## How to start
```sh
# start the VM
limactl start lima-vm.yaml

# stop and delete the vm
limactl stop -f lima-vm && limactl delete lima-vm
```

## Use kubeconfig file in your host:
From your Latop, use kubeconfig.yaml in the the mounted directory: `/lima-data-host/kubeconfig.yaml`
```sh
export KUBECONFIG=~/.kube/config:./lima-data-host/kubeconfig.yaml
kubectl config use-context lima-k3s-cluster
kubectl get nodes
```

## Debugging
- The logs of provisioning the VM can be found inside the vm:
    ```sh
    limactl shell <lima-vm-name>
    sudo tail -n 20 /var/log/cloud-init-output.log
    ```

- The scripts files must be inside the mounted directory. Then they will be referenced inside the `lima-cidata`, so Lima will be aware of them and run them during the porvisioning. 
  - you can check the mode.system scripts under: `/mnt/lima-cidata/provision.system`
    ```sh
    # e.g:
    sudo cat /mnt/lima-cidata/provision.system/00000000

    # the outupt:
    # bash /lima-data-vm/system-k3s-setup.sh
    ```
  - you can check the mode.user scripts under: `/mnt/lima-cidata/provision.user`
    ```sh
    # e.g:
    sudo cat /mnt/lima-cidata/provision.user/00000001

    # the outupt:
    # bash /lima-data-vm/user-configs.sh
    ```