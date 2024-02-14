from diagrams import Cluster, Diagram, Edge
from diagrams.azure.database import SQLDatabases, DataFactory, BlobStorage, DataLake
from diagrams.azure.analytics import Databricks
from diagrams.azure.network import VirtualNetworks, PrivateEndpoint, NetworkSecurityGroupsClassic
from diagrams.azure.integration import DataCatalog
from diagrams.azure.identity import ActiveDirectory
from diagrams.azure.security import KeyVaults
from diagrams.azure.general import Subscriptions

with Diagram("Azure Data Platform with On-Prem Integration", show=True, graph_attr={"dpi": "300"}, direction="TB"):
    on_prem_sql = SQLDatabases("On-Prem SQL Server")
    with Cluster("Azure Data Platform", direction="TB"):
        ad = ActiveDirectory("Azure AD")
        unity_catalog = DataCatalog("Unity Catalog")
        key_vault = KeyVaults("Key Vault")

        with Cluster("ENV DEV", direction="TB"):
            sub_dev = Subscriptions("Sub-\nDataPlatformDevTest-\n001")

            with Cluster("Databricks Dev", direction="TB"):
                nsg_dbx_dev = NetworkSecurityGroupsClassic("NSG Dev")
                dbx_dev_vnet = VirtualNetworks("dbx dev vnet")
                databricks_dev = Databricks("Databricks Dev")
            with Cluster("Storage Account Dev", direction="TB"):
                landing_storage_dev = BlobStorage("Landing Storage Dev")
                with Cluster("vnet for storage account"):
                    storage_dev_vnet = VirtualNetworks("Storage dev vnet")                
                    datalake_storage_dev = DataLake("Datalake Storage Dev")

            dbx_dev_vnet >> Edge(color="darkgreen", style="bold", label="vnet peering") << storage_dev_vnet
            adf_dev = DataFactory("ADF Dev")
            #privatelink_dev = PrivateEndpoint("Private Link")
            adf_dev >> landing_storage_dev
     

        with Cluster("ENV PROD", direction="TB"):
            sub_prod = Subscriptions("Sub-\nDataPlatformProd-\n001")
            with Cluster("Databricks Prod", direction="TB"):
                nsg_prod = NetworkSecurityGroupsClassic("NSG Prod")
                dbx_prod_vnet = VirtualNetworks("dbx prod vnet")
                databricks_prod = Databricks("Databricks Prod")
            with Cluster("Storage Account Prod", direction="TB"):
                storage_prod_vnet = VirtualNetworks("Storage prod vnet")
                datalake_storage_prod = DataLake("Datalake Storage Prod")
                landing_storage_prod = BlobStorage("Landing Storage Prod")

            dbx_prod_vnet >> Edge(color="darkgreen", style="bold", label="vnet peering") << storage_prod_vnet
            adf_prod = DataFactory("ADF Prod")
            adf_prod >> landing_storage_prod

        on_prem_sql >>[adf_dev, adf_prod]

        [adf_dev, adf_prod, databricks_dev, databricks_prod] >> Edge(color="gold", style="bold") >> key_vault
        [datalake_storage_dev, datalake_storage_prod, databricks_dev, databricks_prod] >> Edge(color="red", style="bold") >> unity_catalog

    databricks_prod >> Edge(color="blue", style="bold") >> landing_storage_prod
    databricks_dev >>  Edge(color="blue", style="bold") >> landing_storage_prod
    Cluster("ENV DEV") >> Edge(color="blue", style="bold") >> Cluster("ENV PROD")
 