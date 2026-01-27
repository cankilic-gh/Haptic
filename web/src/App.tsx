import { IPhoneSimulator } from './components/IPhoneSimulator';
import { MetronomeApp } from './components/MetronomeApp';

const App = () => {
  return (
    <div className="min-h-screen w-full flex items-center justify-center p-8">
      <IPhoneSimulator>
        <MetronomeApp />
      </IPhoneSimulator>
    </div>
  );
};

export default App;
