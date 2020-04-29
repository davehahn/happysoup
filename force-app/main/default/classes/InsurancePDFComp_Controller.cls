public with sharing class InsurancePDFComp_Controller {
     public static insuranceFormData formData {get;set;}

    public InsurancePDFComp_Controller(ApexPages.StandardController ctrl) {
        init();
    }

    public InsurancePDFComp_Controller() {
        init();
    }

    public void init()
    {
        formData = new insuranceFormData(false);
        String certNo = ApexPages.currentPage().getParameters().get('certNo');
        //String firstPaymentDate = ApexPages.currentPage().getParameters().get('fPaymentDate');
        String dateString = ApexPages.currentPage().getParameters().get('fPaymentDate');
        if( dateString != null )
        {
            formData.firstPaymentDate = date.newInstance(Integer.valueOf(dateString.split('-')[0]),
                                                         Integer.valueOf(dateString.split('-')[1]),
                                                         Integer.valueOf(dateString.split('-')[2]));
        }
        //System.debug('**** FRIST PAYMENT DATE ****** ' + firstPaymentDate );
        if(certNo == null) certNo = '-PREVIEW-';

        formData.certificateNo = certNo;
        //formData.firstPaymentDate = firstPaymentDate;

        Id idProject = ApexPages.currentPage().getParameters().get('id');
        if(idProject != null)
        {
            AcctSeed__Project__c project = [SELECT Id,
                                            AcctSeedERP__Work_Order_Number__c,
                                            AcctSeed__Opportunity__c,
                                            Finance_Amount__c,
                                            Finance_Annual_Interest__c,
                                            Finance_Payment_Monthly__c,
                                            Finance_Term__c,
                                            Finance_Principal_After_Term__c,
                                            Finance_Ammortization__c,
                                            Finance_Monthly_Payment_wo_Insurance__c,
                                            Financing_Account__r.Name,
                                            Financing_Account__r.BillingStreet,
                                            Financing_Account__r.BillingCity,
                                            Financing_Account__r.BillingState,
                                            Financing_Account__r.BillingCountry,
                                            Financing_Account__r.BillingPostalCode,
                                            Finance_Compound_Interest__c,
                                            Insurance_Term__c,
                                            Name,
                                            Pre_Insurance_Total__c,
                                            Serial_Number__c,
                                            Serial_Number__r.Name,
                                            Tax_Rate_Retail__c,
                                            (SELECT Id,
                                             GMBLASERP__Total_Price__c,
                                             Insurance_Coverage__c,
                                             AcctSeedERP__Product__r.Name,
                                             AcctSeedERP__Product__r.Family,
                                             AcctSeedERP__Product__r.Is_Residual_Insurance__c,
                                             AcctSeedERP__Product__r.Insurance_Waiting_Period_Days__c,
                                             AcctSeedERP__Product__r.Insured_Monthly_Payments__c,
                                             AcctSeedERP__Product__r.Insurance_Waiting_Period_Type__c,
                                             AcctSeedERP__Product__r.Max_Num_of_Insured_Monthly_Payments__c
                                             FROM AcctSeedERP__Project_Materials__r
                                             WHERE AcctSeedERP__Product__r.RecordTypeId = :LGND_Constants.productRtId_Insurance )
                                            FROM AcctSeed__Project__c
                                            WHERE Id =:idProject];
            formData.insuranceIsTruncated = project.Finance_Term__c > project.Insurance_Term__c;
            formData.insuranceDeclinedLIC = true;
            formData.insuranceDeclinedCIC = true;
            formData.insuranceDeclinedDIC = true;
            formData.insuranceDeclinedDICAP = true;
            formData.financialInstitution = project.Financing_Account__r.Name;
            formData.financialInstitutionStreet = project.Financing_Account__r.BillingStreet;
            formData.financialInstitutionCity = project.Financing_Account__r.BillingCity;
            formData.financialInstitutionState = project.Financing_Account__r.BillingState;
            formData.financialInstitutionCountry = project.Financing_Account__r.BillingCountry;
            formData.financialInstitutionPostalCode = project.Financing_Account__r.BillingPostalCode;
            formData.financedAmount = project.Finance_Amount__c;
            formData.preInsuranceAmount = project.Pre_Insurance_Total__c;
            formData.residualValue = project.Finance_Principal_After_Term__c;
            formData.interestRate = project.Finance_Annual_Interest__c;
            formData.monthlyPayment = project.Finance_Payment_Monthly__c;
            formData.monthlyPayment_wo_Insurance = project.Finance_Monthly_Payment_wo_Insurance__c;
            formData.financeTerm = project.Finance_Term__c;
            formData.amortizationTerm = project.Finance_Ammortization__c;
            formData.totalPremium = 0;
            formData.salesTax = 0;
            formData.totalCost = 0;
            formData.stockNo = project.AcctSeedERP__Work_Order_Number__c;
            formData.vehicleIdentificationNo = project.Serial_Number__r.Name;

            for(AcctSeedERP__Material__c matl : project.AcctSeedERP__Project_Materials__r)
            {
                if(matl.AcctSeedERP__Product__r.Family == 'Life Insurance Coverage')
                {
                    formData.insuranceDeclinedLIC = false;
                    formData.setLife_CI_expiryDate();

                    if(matl.Insurance_Coverage__c == 'Single')
                        formData.debtorOnlyLIC = true;
                    else
                        formData.bothLIC = true;

                    if(matl.AcctSeedERP__Product__r.Is_Residual_Insurance__c)
                    {
                        formData.insuredFinancedAmountLIC = project.Finance_Amount__c - project.Finance_Principal_After_Term__c;
                        formData.insuredResidualValueLIC = project.Finance_Principal_After_Term__c;
                        formData.residualLifePremiumLIC = matl.GMBLASERP__Total_Price__c;
                        formData.insuranceTermResidualLIC = project.Insurance_Term__c;
                        formData.totalPremium += formData.residualLifePremiumLIC;
                    }
                    else
                    {
                        formData.insuredFinancedAmountLIC = project.Finance_Amount__c - project.Finance_Principal_After_Term__c;
                        if( formData.lifePremiumLIC == null )
                            formData.lifePremiumLIC = matl.GMBLASERP__Total_Price__c;
                        //else
                            //formData.lifePremiumLIC += matl.GMBLASERP__Total_Price__c;
                        formData.insuranceTermLIC = project.Insurance_Term__c;
                        formData.totalPremium += matl.GMBLASERP__Total_Price__c;
                    }
                    //formData.typeWaitingPeriodDIC = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Type__c;
                    //formData.waitingPeriodDIC = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Days__c;
                    //formData.insuredMonthlyPaymentDIC = project.Finance_Payment_Monthly__c;
                }
                else if(matl.AcctSeedERP__Product__r.Family == 'Loss of Employment Coverage')
                {
                    formData.insuranceDeclinedLOE = false;
                    formData.insuredMonthlyPaymentLOE = matl.AcctSeedERP__Product__r.Insured_Monthly_Payments__c;
                    Decimal a = (project.Finance_Compound_Interest__c * matl.GMBLASERP__Total_Price__c);
                    Decimal ab = Math.pow( (1 + project.Finance_Compound_Interest__c).doubleValue(), -(project.Finance_Ammortization__c * project.Finance_Compound_Interest__c / 12).doubleValue());
                    Decimal b = (1 - ( ab ));
                    Decimal c = ( 12 / project.Finance_Compound_Interest__c);
                    formData.insuranceMonthlyPaymentLOE = a / b / c;
                    formData.waitingPeriodLOE = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Days__c;
                    formData.typeWaitingPeriodLOE = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Type__c;
                    formData.loePremium = matl.GMBLASERP__Total_Price__c;
                    formData.totalPremium += formData.loePremium;
                    //if( formData.lifePremiumLIC == null )
                    //    formData.lifePremiumLIC = matl.GMBLASERP__Total_Price__c;
                    //else
                    //    formData.lifePremiumLIC += matl.GMBLASERP__Total_Price__c;
                }
                else if(matl.AcctSeedERP__Product__r.Family == 'Critical Illness Coverage')
                {
                    formData.insuranceDeclinedCIC = false;
                    formData.setLife_CI_expiryDate();

                    if(matl.Insurance_Coverage__c == 'Single')
                        formData.debtorOnlyCIC = true;
                    else
                        formData.bothCIC = true;

                    if(matl.AcctSeedERP__Product__r.Is_Residual_Insurance__c)
                    {
                        formData.insuredResidualValueCIC = project.Finance_Principal_After_Term__c;
                        formData.residualCIPremiumCIC = matl.GMBLASERP__Total_Price__c;
                        formData.insuranceTermResidualCIC = project.Insurance_Term__c;
                        formData.totalPremium += formData.residualCIPremiumCIC;
                    }
                    else
                    {
                        formData.insuredFinancedAmountCIC = project.Finance_Amount__c - project.Finance_Principal_After_Term__c;
                        formData.ciPremiumCIC = matl.GMBLASERP__Total_Price__c;
                        formData.insuranceTermCIC = project.Insurance_Term__c;
                        formData.totalPremium += formData.ciPremiumCIC;
                    }
                }
                else if(matl.AcctSeedERP__Product__r.Family == 'Disability Insurance Coverage')
                {
                    formData.insuranceDeclinedDIC = false;
                    formData.setDisability_expiryDate();
                    if(matl.Insurance_Coverage__c == 'Single')
                        formData.debtorOnlyDIC = true;
                    else
                        formData.bothDIC = true;

                    formData.insuredMonthlyPaymentDIC = 0;
                    formData.disabilityPremiumDIC = matl.GMBLASERP__Total_Price__c;
                    formData.insuranceTermDIC = project.Insurance_Term__c;
                    formData.totalPremium += formData.disabilityPremiumDIC;
                    formData.typeWaitingPeriodDIC = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Type__c;
                    formData.waitingPeriodDIC = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Days__c;
                    formData.insuredMonthlyPaymentDIC = project.Finance_Payment_Monthly__c;
                    if(matl.AcctSeedERP__Product__r.Max_Num_of_Insured_Monthly_Payments__c == 'Full Term')
                        formData.fullTermInsuranceDIC = true;
                    else if(matl.AcctSeedERP__Product__r.Max_Num_of_Insured_Monthly_Payments__c == 'Recurring ( 6 per claim )')
                        formData.recurringInsuranceDIC = true;
                    else if(matl.AcctSeedERP__Product__r.Max_Num_of_Insured_Monthly_Payments__c == 'Variable - 12 months'){
                        formData.variableInsuranceDIC = true;
                        formData.variable12InsuranceDIC = true;
                    }else if(matl.AcctSeedERP__Product__r.Max_Num_of_Insured_Monthly_Payments__c == 'Variable - 24 months'){
                        formData.variableInsuranceDIC = true;
                        formData.variable24InsuranceDIC = true;
                    }
                }
                else if(matl.AcctSeedERP__Product__r.Family == 'Accidental Coverage')
                {
                    formData.insuranceDeclinedDICAP = false;
                    if(matl.Insurance_Coverage__c == 'Single')
                        formData.debtorOnlyDICAP = true;
                    else
                        formData.bothDICAP = true;

                    formData.insuredMonthlyPaymentDICAP = 0;
                    formData.typeWaitingPeriodDICAP = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Type__c;
                    formData.waitingPeriodDICAP = matl.AcctSeedERP__Product__r.Insurance_Waiting_Period_Days__c;
                    formData.disabilityPremiumDICAP = matl.GMBLASERP__Total_Price__c;
                    formData.insuranceTermDICAP = project.Insurance_Term__c;
                    formData.totalPremium += formData.disabilityPremiumDICAP;
                    formData.insuredMonthlyPaymentDICAP = project.Finance_Payment_Monthly__c;
                }
            }

            if( project.Tax_Rate_Retail__c != null &&
               project.Tax_Rate_Retail__c <> 0 &&
               formData.totalPremium <> 0 )
            {
                formData.salesTax = (project.Tax_Rate_Retail__c * formData.totalPremium) / 100;
            }
            formData.totalCost = formData.totalPremium + formData.salesTax;


            formData.financedAmountWithIntrest = formData.monthlyPayment * formData.financeTerm;

            /// Load Debtor - Co-Debtor Information
            for(OpportunityContactRole ocr : [SELECT Id,
                                              Role,
                                              Contact.LastName,
                                              Contact.FirstName,
                                              Contact.MiddleName,
                                              Contact.Phone,
                                              Contact.Email,
                                              Contact.Birthdate,
                                              Contact.Account.BillingCity,
                                              Contact.Account.BillingStreet,
                                              Contact.Account.BillingState,
                                              Contact.Account.BillingPostalCode,
                                              Contact.Tax_Exempt_Status_Card_Number__c,
                                              Contact.Gender__c
                                              FROM OpportunityContactRole
                                              WHERE OpportunityId =:project.AcctSeed__Opportunity__c
                                              AND Role IN ('Buyer','Co-Buyer')])
            {
                if(ocr.Role == 'Buyer')
                {
                    formData.surnameDebtor = ocr.Contact.LastName;
                    formData.firstNameDebtor = ocr.Contact.FirstName;
                    formData.initialDebtor = ocr.Contact.MiddleName;
                    formData.telephoneDebtor = ocr.Contact.Phone;
                    formData.birthDateDebtor = ocr.Contact.Birthdate;
                    formData.emailDebtor = ocr.Contact.Email;
                    formData.aptNoDebtor = '';
                    formData.streetAddressDebtor = ocr.Contact.Account.BillingStreet;
                    formData.cityDebtor = ocr.Contact.Account.BillingCity;
                    formData.provinceDebtor = ocr.Contact.Account.BillingState;
                    formData.postalCodeDebtor = ocr.Contact.Account.BillingPostalCode;
                    formData.statusCardNoDebtor = ocr.Contact.Tax_Exempt_Status_Card_Number__c;
                    formData.genderDebtor = ocr.Contact.Gender__c;
                }
                else if(ocr.Role == 'Co-Buyer')
                {
                    formData.surnameCoDebtor = ocr.Contact.LastName;
                    formData.firstNameCoDebtor = ocr.Contact.FirstName;
                    formData.initialCoDebtor = ocr.Contact.MiddleName;
                    formData.telephoneCoDebtor = ocr.Contact.Phone;
                    formData.birthDateCoDebtor = ocr.Contact.Birthdate;
                    formData.aptNoCoDebtor = '';
                    formData.streetAddressCoDebtor = ocr.Contact.Account.BillingStreet;
                    formData.cityCoDebtor = ocr.Contact.Account.BillingCity;
                    formData.provinceCoDebtor = ocr.Contact.Account.BillingState;
                    formData.postalCodeCoDebtor = ocr.Contact.Account.BillingPostalCode;
                    formData.statusCardNoCoDebtor = ocr.Contact.Tax_Exempt_Status_Card_Number__c;
                    formData.genderCoDebtor = ocr.Contact.Gender__c;
                }
            }

        }
    }

    public class insuranceFormData{
        public String stockNo{get;set;}
        public String retailerNo{get;set;}
        public Date requestedEffectiveInsuranceDate{get;set;}
        public Date effectiveInsuranceDate{get;set;}

        public Date firstPaymentDate{get;set;}
        public String certificateNo{get;set;}
        public String creditorNo{get;set;}
        public Date approvalDate{get;set;}
        public Date expiryDateLifeCIInsuranceDate{get;set;}
        public Date expiryDateDisabilityInsuranceDate{get;set;}
        public Date expiryInsuranceDate{get;set;}
        // Creditor
        public String groupPolicyHolder{get;set;}
        public String creditorGroupPolicyHolder{get;set;}
        public String financialInstitution{get;set;}
        public String financialInstitutionStreet { get; set; }
        public String financialInstitutionCity { get; set; }
        public String financialInstitutionState { get; set; }
        public String financialInstitutionCountry { get; set; }
        public String financialInstitutionPostalCode { get; set; }
        public String hoUseOnlyCreditor{get;set;}
        // Debtor
        public String surnameDebtor{get;set;}
        public String firstNameDebtor{get;set;}
        public String initialDebtor{get;set;}
        public String telephoneDebtor{get;set;}
        public Date birthDateDebtor{get;set;}
        public String aptNoDebtor{get;set;}
        public String streetAddressDebtor{get;set;}
        public String cityDebtor{get;set;}
        public String provinceDebtor{get;set;}
        public String postalCodeDebtor{get;set;}
        public String hoUseOnlyDebtor{get;set;}
        public String genderDebtor{get;set;}
        public String emailDebtor{get;set;}
        // Co-Debtor
        public String surnameCoDebtor{get;set;}
        public String firstNameCoDebtor{get;set;}
        public String initialCoDebtor{get;set;}
        public String telephoneCoDebtor{get;set;}
        public Date birthDateCoDebtor{get;set;}
        public String aptNoCoDebtor{get;set;}
        public String streetAddressCoDebtor{get;set;}
        public String cityCoDebtor{get;set;}
        public String provinceCoDebtor{get;set;}
        public String postalCodeCoDebtor{get;set;}
        public String hoUseOnlyCoDebtor{get;set;}
        public String genderCoDebtor{get;set;}
        public String emailCoDebtor{get;set;}
        // Finance
        public Decimal financedAmount{get;set;}
        public Decimal preInsuranceAmount { get; set; }
        public Decimal residualValue{get;set;}
        public Decimal interestRate{get;set;}
        public String softwareCompany{get;set;}
        public Decimal monthlyPayment{get;set;}
        public String dealType{get;set;}
        public Decimal financeTerm{
            get;
            set {
                this.financeTerm = value;
                if( value != null )
                    this.expiryInsuranceDate = Date.today().addMonths( Integer.valueOf( value ) );
            }
        }
        public Decimal amortizationTerm{get;set;}
        // Life Insurance Coverage
        public Boolean debtorOnlyLIC{get;set;}
        public Boolean coDebtorOnlyLIC{get;set;}
        public Boolean bothLIC{get;set;}
        public Boolean insuranceDeclinedLIC{get;set;}
        public Decimal insuredFinancedAmountLIC{get;set;}
        public Decimal insuranceTermLIC{get;set;}
        public Decimal lifePremiumLIC{get;set;}
        public Decimal insuredResidualValueLIC{get;set;}
        public Decimal insuranceTermResidualLIC{get;set;}
        public Decimal residualLifePremiumLIC{get;set;}
        // CRITICAL ILLNESS (CI) COVERAGE
        public Boolean debtorOnlyCIC{get;set;}
        public Boolean coDebtorOnlyCIC{get;set;}
        public Boolean bothCIC{get;set;}
        public Boolean insuranceDeclinedCIC{ get;set;}
        public Decimal insuredFinancedAmountCIC{get;set;}
        public Decimal insuranceTermCIC{get;set;}
        public Decimal ciPremiumCIC{get;set;}
        public Decimal insuredResidualValueCIC{get;set;}
        public Decimal insuranceTermResidualCIC{get;set;}
        public Decimal residualCIPremiumCIC{get;set;}
        // DISABILITY INSURANCE COVERAGE - ACCIDENT & SICKNESS
        public Boolean debtorOnlyDIC{get;set;}
        public Boolean coDebtorOnlyDIC{get;set;}
        public Boolean bothDIC{get;set;}
        public Boolean insuranceDeclinedDIC{get;set;}
        public String waitingPeriodDIC{get;set;}
        public String typeWaitingPeriodDIC{get;set;}
        public Decimal maxInsuredMonthlyPaymentDIC{get;set;}
        public Decimal insuredMonthlyPaymentDIC{get;set;}
        public Decimal insuranceTermDIC{get;set;}
        public Decimal disabilityPremiumDIC{get;set;}
        // DISABILITY INSURANCE COVERAGE - ACCIDENTAL PLUS
        public Boolean debtorOnlyDICAP{get;set;}
        public Boolean coDebtorOnlyDICAP{get;set;}
        public Boolean bothDICAP{get;set;}
        public Boolean insuranceDeclinedDICAP{get;set;}
        public Decimal insuredMonthlyPaymentDICAP{get;set;}
        public Decimal insuranceTermDICAP{get;set;}
        public Decimal disabilityPremiumDICAP{get;set;}
        public String waitingPeriodDICAP{get;set;}
        public String typeWaitingPeriodDICAP{get;set;}
        // LOSS OF EMPLOYMENT COVERAGE
        public Boolean insuranceDeclinedLOE { get; set; }
        public Decimal insuredMonthlyPaymentLOE { get; set; }
        public String waitingPeriodLOE { get; set; }
        public String typeWaitingPeriodLOE { get; set; }
        public Decimal insuranceMonthlyPaymentLOE { get; set; }
        public Decimal loePremium { get; set; }
        // Total
        public Decimal totalPremium{get;set;}
        public Decimal salesTax{get;set;}
        public Decimal totalCost{get;set;}
        // Advantage FORM fields
        public Decimal financedAmountWithIntrest { get; set; }
        public String advantagePlan{get;set;}
        public String vehicleIdentificationNo{get;set;}
        public String statusCardNoDebtor{get;set;}
        public String statusCardNoCoDebtor{get;set;}
        public Boolean leaseFinanceInformation{get;set;}
        public Boolean purchaseFinanceInformation{get;set;}
        public Boolean otherFinanceInformation{get;set;}
        public String otherFinanceInformationName{get;set;}
        public Decimal totalAmountLoanInsured{get;set;}
        public Decimal monthlyPayment_wo_Insurance{ get; set; }
        public Decimal monthlyPaymentLI{get;set;}
        public Decimal insuredTotalLoanAmountLI{get;set;}
        public String involuntarywaitingPeriodLI{get;set;}
        public Boolean lifePlusInsuranceOnly{get;set;}
        public Boolean lifePlusAndInvoluntaryUnemploymentInsurance{get;set;}
        public Boolean ciInsuranceOnly{get;set;}
        public Boolean ciPlusInsuranceOnly{get;set;}
        public Boolean fullTermInsuranceDIC{get;set;}
        public Boolean recurringInsuranceDIC{get;set;}
        public Boolean variableInsuranceDIC{get;set;}
        public Boolean variable12InsuranceDIC{get;set;}
        public Boolean variable24InsuranceDIC{get;set;}
        public Boolean insuranceIsTruncated {get; set;}

        public insuranceFormData(Boolean isTestData)
        {
            Date currentDate = Date.today();
            Date birthDate = null;
            String smallText = '';
            String longText = '';
            String blankText = '';
            String aptNo = null;
            Decimal normalAmount = null;
            Decimal normalNumber = null;

            if(isTestData)
            {
                birthDate = currentDate.addYears(-30);
                aptNo = '12';
                smallText = 'Small Text';
                longText = 'This is Long Text';
                longText = 'This is Long Text';
                normalAmount = 10000;
                normalNumber = 12;
                expiryDateLifeCIInsuranceDate = currentDate;
                expiryDateDisabilityInsuranceDate = currentDate;
                expiryInsuranceDate = currentDate;
            }

            stockNo = smallText;
            retailerNo = '00013336';
            effectiveInsuranceDate = currentDate;
            requestedEffectiveInsuranceDate = currentDate;
            //firstPaymentDate = currentDate;
            certificateNo = smallText;
            creditorNo = 'ON000305';
            //approvalDate = currentDate;

            // Creditor
            groupPolicyHolder = 'Legend Boats';
            creditorGroupPolicyHolder = 'Legend Boats';
            financialInstitution = smallText;
            hoUseOnlyCreditor = smallText;
            // Debtor
            surnameDebtor = longText;
            firstNameDebtor = smallText;
            initialDebtor = blankText;
            telephoneDebtor = smallText;
            birthDateDebtor = birthDate;
            aptNoDebtor = aptNo;
            streetAddressDebtor = smallText;
            cityDebtor = smallText;
            provinceDebtor = smallText;
            postalCodeDebtor = smallText;
            hoUseOnlyDebtor = smallText;
            genderDebtor = '';
            emailDebtor = '';
            // Co-Debtor
            surnameCoDebtor = longText;
            firstNameCoDebtor = smallText;
            initialCoDebtor = blankText;
            telephoneCoDebtor = smallText;
            birthDateCoDebtor = birthDate;
            aptNoCoDebtor = aptNo;
            streetAddressCoDebtor = smallText;
            cityCoDebtor = smallText;
            provinceCoDebtor = smallText;
            postalCodeCoDebtor = smallText;
            hoUseOnlyCoDebtor = smallText;
            genderCoDebtor = '';
            emailCoDebtor = '';
            // Finance
            financedAmount = normalAmount;
            residualValue = normalNumber;
            interestRate = normalNumber;
            softwareCompany = 'Legend Boats';
            monthlyPayment = normalNumber;
            dealType = 'Finance';
            financeTerm = normalNumber;
            amortizationTerm = normalNumber;
            // Life Insurance Coverage
            debtorOnlyLIC = isTestData ? true : false;
            coDebtorOnlyLIC = false;
            bothLIC = false;
            insuranceDeclinedLIC = false;
            insuredFinancedAmountLIC = normalNumber;
            insuranceTermLIC = normalNumber;
            lifePremiumLIC = normalNumber;
            insuredResidualValueLIC = normalNumber;
            insuranceTermResidualLIC = normalNumber;
            residualLifePremiumLIC = normalNumber;
            // CRITICAL ILLNESS (CI) COVERAGE
            debtorOnlyCIC = false;
            coDebtorOnlyCIC = false;
            bothCIC = isTestData ? true : false;
            insuranceDeclinedCIC = false;
            insuredFinancedAmountCIC = normalNumber;
            insuranceTermCIC = normalNumber;
            ciPremiumCIC = normalNumber;
            insuredResidualValueCIC = normalNumber;
            insuranceTermResidualCIC = normalNumber;
            residualCIPremiumCIC = normalNumber;
            // DISABILITY INSURANCE COVERAGE - ACCIDENT & SICKNESS
            debtorOnlyDIC = false;
            coDebtorOnlyDIC = false;
            bothDIC = false;
            insuranceDeclinedDIC = isTestData ? true : false;
            typeWaitingPeriodDIC = smallText;
            maxInsuredMonthlyPaymentDIC = normalNumber;
            insuredMonthlyPaymentDIC = normalNumber;
            insuranceTermDIC = normalNumber;
            disabilityPremiumDIC = normalNumber;
            // DISABILITY INSURANCE COVERAGE - ACCIDENTAL PLUS
            debtorOnlyDICAP = false;
            coDebtorOnlyDICAP = false;
            bothDICAP = isTestData ? true : false;
            insuranceDeclinedDICAP = false;
            insuredMonthlyPaymentDICAP = normalNumber;
            insuranceTermDICAP = normalNumber;
            disabilityPremiumDICAP = normalNumber;
            //LOSS OF EMPLOYMENT COVERAGE
            insuranceDeclinedLOE = true;
            loePremium = 0;
            // Total
            totalPremium = normalAmount;
            salesTax = normalAmount;
            totalCost = normalAmount;
            // Advantage
            advantagePlan = '70-P';
            vehicleIdentificationNo = '';
            statusCardNoDebtor = '';
            statusCardNoCoDebtor = '';
            leaseFinanceInformation = false;
            purchaseFinanceInformation = true;
            otherFinanceInformation = false;
            otherFinanceInformationName = '';
            financialInstitution = '';
            financialInstitutionStreet = '';
            financialInstitutionCity = '';
            financialInstitutionState = '';
            financialInstitutionCountry = '';
            financialInstitutionPostalCode = '';
            totalAmountLoanInsured = normalNumber;
            monthlyPaymentLI = normalNumber;
            insuredTotalLoanAmountLI = normalNumber;
            involuntarywaitingPeriodLI = '';
            lifePlusInsuranceOnly = false;
            lifePlusAndInvoluntaryUnemploymentInsurance = false;
            ciInsuranceOnly = false;
            ciPlusInsuranceOnly = false;
            fullTermInsuranceDIC = false;
            recurringInsuranceDIC = false;
            variableInsuranceDIC = false;
            variable12InsuranceDIC = false;
            variable24InsuranceDIC = false;
        }

        public void setLife_CI_expiryDate()
        {
            if( this.expiryDateLifeCIInsuranceDate == null )
            {
                System.debug( 'Finance Term = ' + this.financeTerm );
                Date cDate = Date.today();
                Integer term = this.financeTerm == null ? 0 : Integer.valueOf( this.financeTerm );
                this.expiryDateLifeCIInsuranceDate = cDate.addMonths( term );
            }
        }

        public void setDisability_expiryDate()
        {
            if( this.expiryDateDisabilityInsuranceDate == null )
            {
                Date cDate = Date.today();
                Integer term = this.financeTerm == null ? 0 : Integer.valueOf( this.financeTerm );
                this.expiryDateDisabilityInsuranceDate = cDate.addMonths( term );
            }
        }
    }
}