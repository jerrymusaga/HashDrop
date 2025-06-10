import Link from "next/link";
const Footer: React.FC = () => {
  return (
    <footer className="bg-slate-900 text-slate-300 py-8 border-t border-slate-800">
      <div className=" px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row justify-between items-center">
        <div className="mb-4 md:mb-0">
          <p className="text-lg font-bold">Hashdrop</p>
          <p className="text-sm">Social Proof, Tokenized. Powered by Chainlink.</p>
        </div>
        <div className="flex space-x-6">
          <Link href="/docs" className="hover:text-teal-400 transition">Docs</Link>
          <Link href="/privacy" className="hover:text-teal-400 transition">Privacy Policy</Link>
          <Link href="/terms" className="hover:text-teal-400 transition">Terms of Service</Link>
          <a href="https://twitter.com/hashdrop" className="hover:text-teal-400 transition">Twitter</a>
          <a href="https://discord.gg/hashdrop" className="hover:text-teal-400 transition">Discord</a>
        </div>
        <p className="text-sm mt-4 md:mt-0">&copy; 2025 Hashdrop. All rights reserved.</p>
      </div>
    </footer>
  );
};

export default Footer;