using Baguettepic.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Baguettepic
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();
            CatalogCacheService.Instance.StartWarmup();
        }

        protected override Window CreateWindow(IActivationState? activationState)
        {
            return new Window(new AppShell());
        }
    }
}