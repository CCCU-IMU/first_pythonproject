from pathlib import Path
import tempfile
import unittest

from first_pythonproject.cli import main
from first_pythonproject.vcf import (
    fst_between_populations,
    load_population_map,
    nucleotide_diversity,
    parse_vcf,
    tajimas_d,
)


VCF = """##fileformat=VCFv4.2
#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\tS2\tS3\tS4
1\t100\trs1\tA\tG\t.\tPASS\t.\tGT\t0/0\t0/1\t1/1\t0/1
1\t200\trs2\tC\tT\t.\tPASS\t.\tGT\t0/1\t0/1\t1/1\t1/1
1\t12000\trs3\tG\tA\t.\tPASS\t.\tGT\t0/0\t0/0\t0/1\t1/1
"""

POPS = """FID\tIID\tGroup
F1\tS1\tPopA
F1\tS2\tPopA
F2\tS3\tPopB
F2\tS4\tPopB
"""


class VcfUtilitiesTest(unittest.TestCase):
    def test_statistics_and_cli(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            vcf_path = tmp_path / "demo.vcf"
            pop_path = tmp_path / "populations.tsv"
            outdir = tmp_path / "out"
            vcf_path.write_text(VCF, encoding="utf-8")
            pop_path.write_text(POPS, encoding="utf-8")

            samples, variants = parse_vcf(vcf_path)
            self.assertEqual(samples, ["S1", "S2", "S3", "S4"])
            self.assertEqual(len(variants), 3)

            population_map = load_population_map(pop_path)
            self.assertEqual(population_map["S3"], "PopB")

            pi_rows = nucleotide_diversity(variants, window_size=10000)
            tajima_rows = tajimas_d(variants, sample_count=len(samples), window_size=10000)
            fst_rows = fst_between_populations(variants, samples, population_map, "PopA", "PopB")
            self.assertGreaterEqual(len(pi_rows), 2)
            self.assertGreaterEqual(len(tajima_rows), 1)
            self.assertEqual(len(fst_rows), 3)
            self.assertGreater(fst_rows[0].fst, 0)

            rc = main(
                [
                    "vcf-stats",
                    "--vcf",
                    str(vcf_path),
                    "--populations",
                    str(pop_path),
                    "--outdir",
                    str(outdir),
                    "--window-size",
                    "10000",
                    "--fst",
                    "PopA",
                    "PopB",
                ]
            )
            self.assertEqual(rc, 0)
            self.assertTrue((outdir / "pi.tsv").exists())
            self.assertTrue((outdir / "tajimas_d.tsv").exists())
            self.assertTrue((outdir / "fst_PopA_vs_PopB.tsv").exists())


if __name__ == "__main__":
    unittest.main()
