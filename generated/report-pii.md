## Potential Personal Identifiable Information (PII)

⚠️ We found the following instances of potentially personally identifying information. This may be completely legitimate but might be worth checking. *As a reminder, privacy legislation in many countries (e.g. GDPR in EU) prohibits the dissemination of personal identifiable information without prior (and documented) consent of individuals.* If indeed you want to publish such information with your replication package, you should probably have obtained IRB approval for this - please check!

**Summary:**
- Data files with PII indicators: 2
- Variables flagged in data: 2
- Code files with PII references: 3
- PII references in code: 397

### Summary of Flagged Files

| File Type | File | Variables/References | PII Categories |
|-----------|------|----------------------|----------------|
| Data | `ward_housingtype.dta` | 1 | lat |
| Data | `wards_population.dta` | 1 | name |
| Code | `01_build_sample.do` | 54 | lon, loc, location, address, lat, name, gender, sex, minute, second, city, coord |
| Code | `02_analysis.do` | 337 | lon, lat, loc, sex, degree, city, name, house, location, coord, son, gender |
| Code | `0_install_dependencies.do` | 6 | loc |

*See [Appendix](report-pii-appendix.md) for detailed listing of all flagged instances.*
