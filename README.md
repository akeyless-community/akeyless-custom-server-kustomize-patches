# Akeyless Custom Server Kustomize Patches

This repo contains a set of kustomize patches for the Akeyless Custom Server designed for custom dynamic and rotated secrets. The patches make using the Akeyless Custom Server with kustomize much easier in that you only need to specify the script you want to use and the rest is taken care of for you.

## Reference

- [Akeyless Custom Rotated Secret](https://docs.akeyless.io/docs/create-a-custom-rotated-secret)
- [Akeyless Custom Dynamic Secret](https://docs.akeyless.io/docs/custom-producer)
- [Kustomize Patches](https://kubectl.docs.kubernetes.io/pages/app_customization/patch.html)
- [Akeyless Custom Server](https://github.com/akeylesslabs/custom-producer/tree/master/custom-server)

## Usage

Edit the [kustomization.yml](kustomization.yml) file to enable the correct script or create your own version of the repo by pressing the "Use this template" button and then add your own script(s) into your own repo.

**Be sure to set the GW_ACCESS_ID to be the admin access ID of the Akeyless Gateway you want to be allowed to call this custom server.**

### Usage with Kustomize to view the output

```sh
kustomize build .
```

### Usage with Kustomize to apply the output

```sh
kustomize build . | kubectl apply -f -
```

### Usage with Kustomize to apply the output with a dry-run

```sh
kustomize build . | kubectl apply -f - --dry-run=client
```

### Usage with kubectl to apply the kustomize output

```sh
kubectl apply -k .
```

## License

[Apache 2.0](LICENSE)
