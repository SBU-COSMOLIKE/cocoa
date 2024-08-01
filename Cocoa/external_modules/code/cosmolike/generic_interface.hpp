#include <carma.h>
#include <armadillo>
#include <map>

#ifndef __COSMOLIKE_GENERIC_INTERFACE_HPP
#define __COSMOLIKE_GENERIC_INTERFACE_HPP

namespace cosmolike_interface
{

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Class RandomNumber
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class RandomNumber
{ // Singleton Class that holds a random number generator
  public:
    static RandomNumber& get_instance()
    {
      static RandomNumber instance;
      return instance;
    }
    ~RandomNumber() = default;

    double get()
    {
      return dist_(mt_);
    }

  protected:
    std::random_device rd_;
    std::mt19937 mt_;
    std::uniform_real_distribution<double> dist_;
  
  private:
    RandomNumber() :
      rd_(),
      mt_(rd_()),
      dist_(0.0, 1.0) {
      };
  
    RandomNumber(RandomNumber const&) = delete;
};

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Class IP (InterfaceProducts)
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class IP
{ // InterfaceProducts: Singleton Class that holds data vector, covariance...
  using Vector = arma::Col<double>;
  using STLVector = std::vector<double>;
  using Matrix = arma::Mat<double>;
  using Cube = arma::Cube<double>;

  public:
    static IP& get_instance()
    {
      static IP instance;
      return instance;
    }

    ~IP() = default;

    // ----------------------------------------------

    bool is_mask_set() const;

    bool is_data_set() const;

    bool is_inv_cov_set() const;

    // ----------------------------------------------

    void set_data(std::string DATA);

    // 3x2pt
    void set_mask(std::string MASK, arma::Col<int>::fixed<3> order);

    // 6x2pt
    void set_mask(std::string MASK, arma::Col<int>::fixed<6> order);

    void set_inv_cov(std::string COV);

    //void set_PMmarg(std::string U_PMmarg_file);

    // ----------------------------------------------

    int get_mask(const int ci) const;

    double get_dv_masked(const int ci) const;

    double get_inv_cov_masked(const int ci, const int cj) const;

    int get_index_sqzd(const int ci) const;

    double get_dv_masked_sqzd(const int ci) const;

    double get_inv_cov_masked_sqzd(const int ci, const int cj) const;

    Vector expand_data_vector_from_sqzd(Vector input) const;

    double get_chi2(STLVector datavector) const;

    // ----------------------------------------------

    int get_ndata() const;

    arma::Col<int> get_mask() const;

    Vector get_dv_masked() const;

    Matrix get_cov_masked() const;

    Matrix get_inv_cov_masked() const;

    int get_ndata_sqzd() const;

    Vector get_dv_masked_sqzd() const;

    Matrix get_cov_masked_sqzd() const;

    Matrix get_inv_cov_masked_sqzd() const;

  private:

    bool is_mask_set_ = false;
    
    bool is_data_set_ = false;
    
    bool is_inv_cov_set_ = false;
    
    int ndata_ = 0;
    
    int ndata_masked_ = 0;                      // for baryon project, reduced dim
    
    std::string mask_filename_;
    
    std::string cov_filename_;
    
    std::string data_filename_;
    
    arma::Col<int> mask_;

    Vector data_masked_;
    
    Matrix cov_masked_;

    arma::Col<int> index_sqzd_;
    
    Matrix inv_cov_masked_;
    
    Vector data_masked_sqzd_;             // for baryon project, reduced dim

    Matrix cov_masked_sqzd_;              // for baryon project, reduced dim

    Matrix inv_cov_masked_sqzd_;          // for baryon project, reduced dim
    
    IP() = default;
    IP(IP const&) = delete;
};

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Class IPCMB (InterfaceProducts - 6x2pt (includes CMB lensing))
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class IPCMB
{
  using Vector = arma::Col<double>;
  using STLVector = std::vector<double>;
  using Matrix = arma::Mat<double>;
  using Cube = arma::Cube<double>;

  public:
    static IPCMB& get_instance()
    {
      static IPCMB instance;
      return instance;
    }

    ~IPCMB() = default;

    // ----------------------------------------------

    bool is_cmb_binmat_set() const;

    bool is_cmb_offset_set() const;

    // ----------------------------------------------

    void set_cmb_binning_mat(std::string BINMAT);

    void set_cmb_theory_offset(std::string OFFSET);

    // ----------------------------------------------

    double get_binning_matrix_with_correction(const int ci, const int cj) const;

    double get_cmb_theory_offset(const int ci) const;

    // ----------------------------------------------

    Matrix get_binning_matrix_with_correction() const;

    Matrix get_cmb_theory_offset() const;

  private:   
    bool is_cmb_binmat_set_ = false;
    
    bool is_cmb_offset_set_ = false;

    int nbp_ = 0;
    
    int ncl_ = 0;

    std::string binmat_filename_;                // LSS x CMB
    
    std::string offset_filename_;                // LSS x CMB
    
    Vector cmb_theory_offset_;                   // LSS x CMB, see Eqn 35 Planck 2018 VIII

    Matrix cmb_binning_matrix_with_correction_;  // LSS x CMB, see Eqn 35 Planck 2018 VIII
    
    IPCMB() = default;
    IPCMB(IP const&) = delete;
};

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Class PointMass
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class PointMass
{// Singleton Class that Evaluate Point Mass Marginalization
  public:
    static PointMass& get_instance()
    {
      static PointMass instance;
      return instance;
    }
    ~PointMass() = default;

    void set_pm_vector(std::vector<double> pm);

    std::vector<double> get_pm_vector() const;

    double get_pm(const int zl, const int zs, const double theta) const;

  private:
    std::vector<double> pm_;

    PointMass() = default;
    
    PointMass(PointMass const&) = delete;
};

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Class BaryonScenario
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class BaryonScenario
{ // Singleton Class that map Baryon Scenario (integer to name)
  public:
    static BaryonScenario& get_instance()
    {
      static BaryonScenario instance;
      return instance;
    }
    ~BaryonScenario() = default;

    int nscenarios() const;

    void set_scenarios(std::string data_sims, std::string scenarios);

    void set_scenarios(std::string scenarios);

    std::string get_scenario(const int i) const;

    std::tuple<std::string,int> select_baryons_sim(const std::string scenario);

  private:
    int nscenarios_;
    std::map<int, std::string> scenarios_;

    BaryonScenario() = default;
    BaryonScenario(BaryonScenario const&) = delete;
};

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GLOBAL FUNCTIONS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

arma::Mat<double> read_table(const std::string file_name);

// https://en.cppreference.com/w/cpp/types/numeric_limits/epsilon
template<class T>
typename std::enable_if<!std::numeric_limits<T>::is_integer, bool>::type 
almost_equal(T x, T y, int ulp = 100)
{
  // the machine epsilon has to be scaled to the magnitude of the values used
  // and multiplied by the desired precision in ULPs (units in the last place)
  return std::fabs(x-y) <= std::numeric_limits<T>::epsilon() * std::fabs(x+y) * ulp
      // unless the result is subnormal
      || std::fabs(x-y) < std::numeric_limits<T>::min();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GLOBAL INIT FUNCTIONS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void init_accuracy_boost(
    const double accuracy_boost, 
    const double sampling_boost,
    const int integration_accuracy
  );

void init_binning_fourier(
    const int Ncl, 
    const double lmin, 
    const double lmax
  );

void init_binning_real(
    const int Ntheta, 
    const double theta_min_arcmin, 
    const double theta_max_arcmin
  );

void init_binning_cmb_bandpower(
    const int Nbp, 
    const double lmin, 
    const double lmax
  );

void init_cosmo_runmode(
    const bool is_linear
  );

void init_cmb(
    const double lmin_kappa_cmb, 
    const double lmax_kappa_cmb, 
    const double fwhm, 
    std::string pixwin_file
  );

void init_cmb_bandpower(
    const int is_cmb_bandpower, 
    const int is_cmb_kkkk_cov_from_simulation, 
    const double alpha
  );

void init_data_vector_size(
    arma::Col<int>::fixed<6> exclude
  );

void init_data_vector_size_3x2pt(
  );

void init_data_vector_size_6x2pt(
  );

void init_distances(
    std::vector<double> io_z, 
    std::vector<double> io_chi
  );

void init_growth(
    std::vector<double> io_z, 
    std::vector<double> io_G
  );

void init_IA(
    const int IA_MODEL, 
    const int IA_REDSHIFT_EVOL
  );

void init_lens_sample(
    std::string multihisto_file, 
    const int Ntomo
  );

void init_linear_power_spectrum(
    std::vector<double> io_log10k,
    std::vector<double> io_z, 
    std::vector<double> io_lnP
  );

void init_non_linear_power_spectrum(
    std::vector<double> io_log10k,
    std::vector<double> io_z, 
    std::vector<double> io_lnP
  );

void init_probes(
    std::string possible_probes
  );

void initial_setup(
  );

void init_source_sample(
    std::string multihisto_file, 
    const int Ntomo
  );

void init_survey(
    std::string surveyname, 
    double area, 
    double sigma_e
  );

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GLOBAL SET FUNCTIONS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

void set_pm(
    std::vector<double> PM
  );

void set_nuisance_bias(
    std::vector<double> B1, 
    std::vector<double> B2, 
    std::vector<double> B_MAG
  );

void set_nuisance_clustering_photoz(
    std::vector<double> CP
  );

void set_nuisance_magnification_bias(
  std::vector<double> B_MAG
  );

void set_nuisance_nonlinear_bias(
    std::vector<double> B1,
    std::vector<double> B2
  );

void set_nuisance_shear_calib(
    std::vector<double> M
  );

void set_nuisance_shear_photoz(
    std::vector<double> SP
  );

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GET FUNCTIONS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

int get_baryon_pca_nscenarios(
  );

std::string get_baryon_pca_scenario_name(
    const int i
  );

std::vector<double> get_data_vector_expanded_from_sqzd(
    std::vector<double> sqzd
  );

matrix get_cov_masked(
  );

matrix get_cov_masked_sqzd(
  );

int get_mask(
    const int i
  );

int get_ndata(
  );

int get_ndata_sqzd(
  );

int get_index_sqzd(
    const int i
  );

double get_baryon_power_spectrum_ratio(
    const double log10k, 
    const double a
  );

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GLOBAL COMPUTE FUNCTIONS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

double compute_chi2(
    std::vector<double> datavector
  );

void compute_ss_real_masked(
    std::vector<double>& data_vector, 
    const int start
  );

void compute_gs_real_masked(
    std::vector<double>& data_vector, 
    const int start
  );

void compute_gg_real_masked(
    std::vector<double>& data_vector, 
    const int start
  );

void compute_gk_real_masked(
    std::vector<double>& data_vector, 
    const int start
  );

void compute_ks_real_masked(
    std::vector<double>& data_vector, 
    const int start
  );

void compute_kk_fourier_masked(
    std::vector<double>& data_vector, 
    const int start
  );

std::vector<double> compute_data_vector_6x2pt_masked(
    arma::Col<int>::fixed<6> order
  );

std::vector<double> compute_data_vector_3x2pt_masked(
    arma::Col<int>::fixed<3> order
  );

double compute_pm(
      const int zl, 
      const int zs, 
      const double theta
    );

}  // namespace cosmolike_interface
#endif // HEADER GUARD