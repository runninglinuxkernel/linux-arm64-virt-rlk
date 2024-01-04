#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/compiler.h>
#include <linux/pci.h>
#include <linux/init.h>
#include <linux/iommu.h>

#define PCI_VENDOR_ID_ARM             0x13b5
#define PCI_DEVICE_ID_SMMU_TEST       0xff80

struct  smmu_test_device {
	struct device *dev;

	void __iomem *reg;
	resource_size_t reg_phys;

	dma_addr_t dma_addr;
	void *buf;
	u64 size;
};

static int smmu_test_alloc_dma(struct pci_dev *pdev, struct smmu_test_device *iommu)
{
	iommu->size = SZ_4K;

	iommu->buf = dma_alloc_coherent(&pdev->dev, iommu->size, &iommu->dma_addr, GFP_KERNEL);
	if (!iommu->buf)
		return -ENOMEM;

	printk("%s ---- iova 0x%llx   dma_addr 0x%llx\n", __func__, (u64)iommu->buf, iommu->dma_addr);

	return 0;
}

static int smmu_test_pci_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
{
	struct device *dev = &pdev->dev;
	struct smmu_test_device *iommu;
	int ret = -EINVAL;
	u64 len;

	ret = pci_enable_device_mem(pdev);
	if (ret < 0)
		return ret;

	ret = pci_request_mem_regions(pdev, KBUILD_MODNAME);
	if (ret < 0)
		goto fail;

	iommu = devm_kzalloc(dev, sizeof(*iommu), GFP_KERNEL);
	if (!iommu)
		goto fail;

	if (!(pci_resource_flags(pdev, 0) & IORESOURCE_MEM))
		goto fail;

	len = pci_resource_len(pdev, 0);

	iommu->reg_phys = pci_resource_start(pdev, 0);
	if (!iommu->reg_phys)
		goto fail;

	printk("%s === reg_phy 0x%llx, len 0x%llx\n", __func__, (u64)iommu->reg_phys, len);

	iommu->reg = devm_ioremap(dev, iommu->reg_phys, len);
	if (!iommu->reg)
		goto fail;

	printk("%s === reg 0x%llx\n", __func__, (u64)iommu->reg);

	iommu->dev = dev;
	dev_set_drvdata(dev, iommu);

	dma_set_mask_and_coherent(dev, DMA_BIT_MASK(64));
	pci_set_master(pdev);

	smmu_test_alloc_dma(pdev, iommu);

	return 0;

fail:
	pci_clear_master(pdev);
	pci_release_regions(pdev);
	pci_disable_device(pdev);
	pci_disable_device(pdev);
	return ret;
}

static void smmu_test_pci_remove(struct pci_dev *pdev)
{
	struct smmu_test_device *iommu = dev_get_drvdata(&pdev->dev);

	dma_free_coherent(&pdev->dev, iommu->size, iommu->buf, iommu->dma_addr);

	pci_clear_master(pdev);
	pci_release_regions(pdev);
	pci_disable_device(pdev);
}

static const struct pci_device_id smmu_test_pci_tbl[] = {
	{PCI_VENDOR_ID_ARM, PCI_DEVICE_ID_SMMU_TEST,
	 PCI_ANY_ID, PCI_ANY_ID, 0, 0, 0},
	{0,}
};

MODULE_DEVICE_TABLE(pci, smmu_test_pci_tbl);

static const struct of_device_id smmu_test_of_match[] = {
	{.compatible = "",},
	{},
};

MODULE_DEVICE_TABLE(of, smmu_test_of_match);

static struct pci_driver smmu_test_pci_driver = {
	.name = KBUILD_MODNAME,
	.id_table = smmu_test_pci_tbl,
	.probe = smmu_test_pci_probe,
	.remove = smmu_test_pci_remove,
	.driver = {
		   .of_match_table = smmu_test_of_match,
		   },
};

module_driver(smmu_test_pci_driver, pci_register_driver, pci_unregister_driver);
MODULE_LICENSE("GPL v2");