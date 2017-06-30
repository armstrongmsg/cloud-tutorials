import getpass
from keystoneauth1 import loading
from keystoneauth1 import session
from novaclient import client
import sys

class OpenStackClient:

    def get_nova_client(self, auth_url, username, password, project_name, project_domain_name, user_domain_name):
        loader = loading.get_plugin_loader('password')
        auth = loader.load_from_options(auth_url=auth_url, 
                                        username=username, 
                                        password=password, 
                                        project_name=project_name, 
                                        project_domain_name=project_domain_name,
                                        user_domain_name=user_domain_name)
        sess = session.Session(auth=auth)
        return client.Client("2", session=sess)
    
    def create_instance(self, instance_name, nova_client, flavor_name, image_name, key_name):
        fl = nova_client.flavors.find(name=flavor_name)
        im = nova_client.glance.find_image(image_name)
        server = nova_client.servers.create(instance_name, flavor=fl, image=im, key_name=key_name)
        return server.id
    
    def delete_instance(self, instance_name, nova_client):
        nova_client.servers.delete(instance_name)

if __name__ == '__main__':
    
    command = sys.argv[1]
    instance_name = sys.argv[2]
    
    password = getpass.getpass()
    os_client = OpenStackClient()
    
    #
    # Creating nova client
    #    
    nova_client = os_client.get_nova_client(auth_url="https://cloud.lsd.ufcg.edu.br:5000/v3/", 
                                              username="armstrongmsg", 
                                              password=password, 
                                              project_name="BigSea", 
                                              project_domain_name="LSD", 
                                              user_domain_name="LSD")
    #
    # Creating instance
    #
    if command == "-c":
        os_client.create_instance(instance_name=instance_name, 
                              nova_client=nova_client,
                              # 2 vCPUs
                              # 4 GB
                              # 80 GB
                              flavor_name="BigSea.l1.medium", 
                              image_name="spark-ubuntu-java8", 
                              key_name="bigsea")
    
    #
    # Deleting instance
    #
    if command == "-d":
        os_client.delete_instance(instance_name, nova_client) 
